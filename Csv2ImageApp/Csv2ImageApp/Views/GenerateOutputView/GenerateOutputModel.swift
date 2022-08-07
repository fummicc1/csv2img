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

    @Published var state: GenerateOutputState

    let csv: Csv

    private var cancellables: Set<AnyCancellable> = []

    init(url: URL, urlType: FileURLType, exportMode: Csv.ExportType = .pdf) {
        self.state = .init(
            url: url,
            fileType: urlType,
            cgImage: nil,
            pdfDocument: nil,
            exportType: exportMode
        )
        do {
            switch urlType {
            case .local:
                self.csv = try Csv.fromFile(url)
            case .network:
                self.csv = try Csv.fromURL(url)
            }
        } catch {
            fatalError("\(error)")
        }

        _state.projectedValue.map(\.exportType)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [weak self] exportType -> AnyCsvExportable? in
                do {
                    return try self?.csv.generate(exportType: exportType)
                } catch {
                    print(error)
                    return nil
                }
            }
            .compactMap { $0 }
            .sink(receiveValue: { exportable in
                self.state.cgImage = nil
                self.state.pdfDocument = nil
                if type(of: exportable.base) == PDFDocument.self {
                    self.state.pdfDocument = (exportable.base as! PDFDocument)
                } else {
                    self.state.cgImage = (exportable.base as! CGImage)
                }
            })
            .store(in: &cancellables)
    }

    func onAppear() {
        do {
            state.cgImage = nil
            state.pdfDocument = nil
            switch state.exportType {
            case .png:
                let out = try csv.generate(exportType: state.exportType).base
                state.cgImage = (out as! CGImage)
            case .pdf:
                state.pdfDocument = try csv.generate(exportType: state.exportType).base as? PDFDocument
            }
        } catch {
            print(error)
        }
    }

    @MainActor
    @discardableResult
    func save() -> Bool {
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
                    return pdf.write(to: url)
                } else if let imgData = state.cgImage?.convertToData() {
                    try imgData.write(to: url)
                    return true
                }
            } catch {
                print(error)
            }
        }
        return false
    }
}


#if os(macOS)
#endif
