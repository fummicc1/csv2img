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

    @Published @MainActor var state: GenerateOutputState
    @Published @MainActor var savedURL: URL?

    let csv: Csv

    private var cancellables: Set<AnyCancellable> = []
    private let queue = DispatchQueue(label: "dev.fummicc1.csv2imgapp.generate-output-model")

    @MainActor
    init(url: URL, urlType: FileURLType, exportMode: Csv.ExportType = .pdf) {
        self.csv = Csv(exportType: exportMode)

        self.state = .init(
            url: url,
            fileType: urlType,
            exportType: exportMode
        )

        Task {
            switch urlType {
            case .local:
                #if os(macOS)
                try await csv.loadFromDisk(url)
                #elseif os(iOS)
                try await csv.loadFromDisk(url, checkAccessSecurityScope: true)
                #endif
            case .network:
                try await csv.loadFromNetwork(url)
            }

            csv.isLoadingPublisher
                .receive(on: DispatchQueue.main)
                .sink { isLoading in
                    self.state.isLoading = isLoading
                }
                .store(in: &cancellables)

            csv.progressPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { progress in
                    self.state.progress = progress
                })
                .store(in: &cancellables)
        }

        _state.projectedValue.map(\.exportType)
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: queue)
            .sink(receiveValue: { exportType in
                Task { [weak self] in
                    guard let self = self else {
                        return
                    }
                    let exportable = try await self.csv.generate(exportType: exportType)
                    await MainActor.run(body: {
                        self.state.cgImage = nil
                        self.state.pdfDocument = nil
                        if type(of: exportable.base) == PDFDocument.self {
                            self.state.pdfDocument = (exportable.base as! PDFDocument)
                        } else {
                            self.state.cgImage = (exportable.base as! CGImage)
                        }
                    })
                }
            })
            .store(in: &cancellables)
    }

    func onAppear() async {
        do {
            await MainActor.run(body: {
                state.cgImage = nil
                state.pdfDocument = nil
            })
            switch await state.exportType {
            case .png:
                let out = try await csv.generate(exportType: state.exportType).base
                await MainActor.run(body: {
                    state.cgImage = (out as! CGImage)
                })
            case .pdf:
                let out = try await csv.generate(exportType: state.exportType).base as? PDFDocument
                await MainActor.run(body: {
                    state.pdfDocument = out
                })
            }
        } catch {
            print(error)
        }
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
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
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
