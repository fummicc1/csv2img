//
//  GenerateOutputModel.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import Csv2Img
import PDFKit
import SwiftUI
import Combine


enum GenerateOutputModelError: Error {
}

class GenerateOutputModel: ObservableObject {

    @Published @MainActor private(set) var state: GenerateOutputState    
    @Published @MainActor private(set) var savedURL: URL?

    @Published private var cachedCsv: Csv? {
        didSet {
            guard let cachedCsv else {
                return
            }
            Task { @MainActor in
                let encoding = await cachedCsv.encoding
                state.encoding = encoding
                let exportType = await cachedCsv.exportType
                state.exportType = exportType
            }
        }
    }

    private var cancellables: Set<AnyCancellable> = []
    private let queue = DispatchQueue(label: "dev.fummicc1.csv2imgapp.generate-output-model", attributes: .concurrent)
    private var csvTask: Task<Void, Never>?

    deinit {
        csvTask?.cancel()
    }

    @MainActor
    init(url: URL, urlType: FileURLType, encoding: String.Encoding = .utf8, exportMode: Csv.ExportType = .pdf) {
        self.state = .init(
            url: url,
            fileType: urlType,
            encoding: encoding,
            exportType: exportMode
        )
        Task {
            await updateCachedCsv()
        }
    }

    @MainActor
    func update<V>(keyPath: WritableKeyPath<GenerateOutputState, V>, value: V) {
        state[keyPath: keyPath] = value
    }

    @MainActor
    func onAppear() async {
        _state.projectedValue
            .map(\.exportType)
            .removeDuplicates()
            .combineLatest(
                _state.projectedValue
                    .map(\.encoding)
                    .removeDuplicates()
            )
            .receive(on: queue)
            .share()
            .sink { (_, _) in
                Task {
                    await self.updateCachedCsv()
                }
            }
            .store(in: &cancellables)
    }

    func updateCachedCsv() async {
        let exportMode = await state.exportType
        let encoding = await state.encoding
        let url = await state.url
        let fileType = await state.fileType
        let csv: Csv?
        do {
            switch fileType {
            case .local:
                csv = try Csv.loadFromDisk(url, encoding: encoding, exportType: exportMode)
            case .network:
                csv = try Csv.loadFromNetwork(url, encoding: encoding, exportType: exportMode)
            }
        } catch {
            csv = await MainActor.run(body: {
                self.state.errorMessage = "Error happened:\n\(error)"
                return self.cachedCsv
            })
        }
        guard let csv else {
            return
        }

        await MainActor.run(body: {
            cachedCsv = csv
        })
        csvTask?.cancel()
        csvTask = Task {
            Task {
                do {
                    let exportable = try await csv.generate(exportType: exportMode)
                    if type(of: exportable.base) == PDFDocument.self {
                        await self.update(keyPath: \.pdfDocument, value: (exportable.base as! PDFDocument))
                    } else {
                        await self.update(keyPath: \.cgImage, value: (exportable.base as! CGImage))
                    }
                } catch {

                }
            }
            Task {
                for await isLoading in csv.isLoadingPublisher.values {
                    await MainActor.run(body: {
                        state.isLoading = isLoading
                    })
                }
            }
            Task {
                for await progress in csv.progressPublisher.values {
                    await MainActor.run(body: {
                        state.progress = progress
                    })
                }
            }
        }
    }

    @MainActor
    func clearError() {
        state.errorMessage = nil
    }

    @MainActor
    @discardableResult
    func save() -> Bool {
        #if os(macOS)
        save_macOS()
        #elseif os(iOS)
        save_iOS()
        #endif
    }
}

#if os(macOS)
extension GenerateOutputModel {
    @MainActor
    private func save_macOS() -> Bool {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = state.url.lastPathComponent
        panel.allowedContentTypes = [state.exportType.utType]
        let result = panel.runModal()
        if result == .OK {
            guard let url = panel.url else {
                return false
            }
            do {
                if let pdf = state.pdfDocument {
                    if pdf.write(to: url) {
                        savedURL = url
                        return true
                    }
                } else if let imgData = state.cgImage?.convertToData() {
                    try imgData.write(to: url)
                    savedURL = url
                    return true
                }
            } catch {
                print(error)
            }
        }
        return false
    }
}
#elseif os(iOS)
extension GenerateOutputModel {
    @MainActor
    private func save_iOS() -> Bool {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return false
        }
        guard let fileName = state.url.lastPathComponent.split(separator: ".").first else {
            return false
        }
        url.appendPathComponent(String(fileName), conformingTo: state.exportType.utType)
        if let pdf = state.pdfDocument, state.exportType == .pdf {
            if pdf.write(to: url) {
                savedURL = url
                return true
            }
        } else if let image = state.cgImage, state.exportType == .png {
            do {
                try image.convertToData()?.write(to: url)
                savedURL = url
                return true
            } catch {
                print(error)
            }
        }

        return false
    }
}
#endif
