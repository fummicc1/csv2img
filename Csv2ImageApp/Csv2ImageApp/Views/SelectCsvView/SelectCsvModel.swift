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
    case invalidNetworkUrl(string: String)
}

class SelectCsvModel: NSObject, ObservableObject {

    @Published var selectedCsv: SelectedCsvState?
    @Published var networkUrlText: String = ""
    @Published var error: String?

    @MainActor
    func selectFileOnDisk() async {
        #if os(macOS)
        await selectFileOnDisk_macOS()
        #elseif os(iOS)
        await selectFileOnDisk_iOS()
        #endif
    }

    @MainActor
    func selectFileOnTheInternet() async {
        guard let url = URL(string: networkUrlText) else {
            let error = SelectCsvModelError.invalidNetworkUrl(string: networkUrlText)
            self.error = "\(error)"
            return
        }
        withAnimation {
            selectedCsv = .init(fileType: .network, url: url)
        }
    }
}


#if os(macOS)
import AppKit
extension SelectCsvModel {
    @MainActor
    private func selectFileOnDisk_macOS() async {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        let result = panel.runModal()
        if result == .OK {
            guard let url = panel.url else {
                error = "\(SelectCsvModelError.fileNotFound)"
                return
            }
            withAnimation {
                selectedCsv = SelectedCsvState(fileType: .local, url: url)
            }
        }
    }
}
#elseif os(iOS)
import UIKit
extension SelectCsvModel: UIDocumentPickerDelegate {
    @MainActor
    private func selectFileOnDisk_iOS() async {
        let viewController = UIDocumentPickerViewController(
            forOpeningContentTypes: [.commaSeparatedText]
        )
        viewController.delegate = self
        Application.shared.activeRootViewController?.present(
            viewController, animated: true
        )
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        withAnimation {
            selectedCsv = .init(fileType: .local, url: url)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        selectedCsv = nil
    }
}
#endif
