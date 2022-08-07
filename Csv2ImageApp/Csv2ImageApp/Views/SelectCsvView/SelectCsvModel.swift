//
//  SelectCsvModel.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import SwiftUI

enum SelectCsvModelError: Error {
    case fileNotFound
}

class SelectCsvModel: ObservableObject {

    @MainActor
    func selectFileOnDisk() async throws -> URL? {
        #if os(macOS)
        try await selectFileOnDisk_macOS()
        #elseif os(iOS)
        fatalError()
        #endif
    }
}


#if os(macOS)
import AppKit
extension SelectCsvModel {
    @MainActor
    private func selectFileOnDisk_macOS() async throws -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        let result = panel.runModal()
        if result == .OK {
            guard let url = panel.url else {
                throw SelectCsvModelError.fileNotFound
            }
            return url
        } else {
            return nil
        }
    }
}
#endif
