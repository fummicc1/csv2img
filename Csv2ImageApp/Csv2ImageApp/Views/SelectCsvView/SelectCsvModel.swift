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
    case invalidNetworkURL(string: String)
    case invalidCsvURL(string: String)
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
        guard validateCsvURL(path: networkUrlText) else {
            let error = SelectCsvModelError.invalidCsvURL(string: networkUrlText)
            self.error = "\(error)"
            return
        }
        guard let url = URL(string: networkUrlText) else {
            let error = SelectCsvModelError.invalidNetworkURL(string: networkUrlText)
            self.error = "\(error)"
            return
        }
        withAnimation {
            selectedCsv = .init(fileType: .network, url: url)
        }
    }

    func validateCsvURL(path: String) -> Bool {
        guard let `extension` = path.split(separator: "/").last, `extension`.contains(".csv") else {
            return false
        }
        return true
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

    @MainActor func openFolderApp() {
        guard var urlPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.absoluteString else {
            return
        }
        let newPath = urlPath.replacingOccurrences(of: "file://", with: "shareddocuments://")
        guard let url = URL(string: newPath) else {
            return
        }
        if Application.shared.canOpenURL(url) {
            Application.shared.open(url)
        }
    }
}
#endif
