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
    @Published @MainActor private(set) var encoding: String.Encoding
    @Published @MainActor private(set) var savedURL: URL?

    private var csvTask: Task<Void, Never>?

    @Published @MainActor private(set) var csv: Csv {
        didSet {
            csvTask?.cancel()
            csvTask = Task { [weak self] in
                Task {
                    let exportType = await csv.exportType
                    let encoding = await csv.encoding
                    guard let encoding, let exportable = try? await csv.generate(exportType: exportType) else {
                        return
                    }
                    self?.encoding = encoding
                    self?.state.cgImage = nil
                    self?.state.pdfDocument = nil
                    if type(of: exportable.base) == PDFDocument.self {
                        self?.state.pdfDocument = (exportable.base as! PDFDocument)
                    } else {
                        self?.state.cgImage = (exportable.base as! CGImage)
                    }
                }

                Task {
                    for await isLoading in csv.isLoadingPublisher.values {
                        self?.state.isLoading = isLoading
                    }
                }
                Task {
                    for await progress in csv.progressPublisher.values {
                        self?.state.progress = progress
                    }
                }
            }
        }
    }

    private var cancellables: Set<AnyCancellable> = []
    private let queue = DispatchQueue(label: "dev.fummicc1.csv2imgapp.generate-output-model")

    @MainActor
    init(url: URL, urlType: FileURLType, encoding: String.Encoding = .utf8, exportMode: Csv.ExportType = .pdf) {
        self.encoding = encoding
        self.state = .init(
            url: url,
            fileType: urlType,
            exportType: exportMode
        )

        do {
            switch urlType {
            case .local:
                self.csv = try Csv.loadFromDisk(url, encoding: encoding, exportType: exportMode)
            case .network:
                self.csv = try Csv.loadFromNetwork(url, encoding: encoding, exportType: exportMode)
            }
        } catch {
            self.csv = Csv(encoding: encoding, exportType: exportMode)
        }
    }

    @MainActor
    func onAppear() async {
        let urlType = state.fileType
        let exportMode = state.exportType
        let url = state.url
        do {
            switch urlType {
            case .local:
                self.csv = try Csv.loadFromDisk(url, encoding: encoding, exportType: exportMode)
            case .network:
                self.csv = try Csv.loadFromNetwork(url, encoding: encoding, exportType: exportMode)
            }
            self.encoding = encoding
        } catch {
            self.csv = Csv(encoding: encoding, exportType: exportMode)
            self.state.errorMessage = "Error happened:\n\(error)"
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

        do {
            await MainActor.run(body: {
                state.cgImage = nil
                state.pdfDocument = nil
            })
            switch state.exportType {
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
    func update<V>(keyPath: WritableKeyPath<GenerateOutputState, V>, value: V) {
        self.state[keyPath: keyPath] = value
    }

    @MainActor
    func update(encoding: String.Encoding) {
        let exportMode = state.exportType
        let url = state.url
        let fileType = state.fileType
        let csv: Csv
        do {
            switch fileType {
            case .local:
                csv = try Csv.loadFromDisk(url, encoding: encoding, exportType: exportMode)
            case .network:
                csv = try Csv.loadFromNetwork(url, encoding: encoding, exportType: exportMode)
            }
        } catch {
            self.state.errorMessage = "Error happened:\n\(error)"
            csv = self.csv
        }
        self.csv = csv
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
