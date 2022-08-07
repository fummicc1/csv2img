//
//  SelectCsvView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img
import CoreData
import PDFKit

enum CsvImageAppError: Swift.Error {
    case invalidNetworkURL(url: String)
    case outputFileNameIsEmpty
    case underlying(Error)

    var message: String {
        switch self {
        case .invalidNetworkURL(let url):
            return "Invalid URL: \(url)"
        case .outputFileNameIsEmpty:
            return "Empty Output FileName"
        case .underlying(let error):
            return "\(error)"
        }
    }
}

struct SelectCsvView: View {

    @Binding var selectedImageUrl: URL?

    var body: some View {
        #if os(macOS)
        SelectCsvView_macOS(selectedImageUrl: _selectedImageUrl)
        #elseif os(iOS)
        SelectCsvView_iOS()
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        fatalError()
    }
}
