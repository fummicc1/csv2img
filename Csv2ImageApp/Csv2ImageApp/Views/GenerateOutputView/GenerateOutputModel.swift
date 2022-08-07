//
//  GenerateOutputModel.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import Foundation
import SwiftUI

enum GenerateOutputModelError: Error {
}

class GenerateOutputModel: ObservableObject {

    @Published var state: GenerateOutputState

    init(url: URL, urlType: FileURLType) {
        self.state = .init(
            url: url,
            fileType: urlType,
            data: nil,
            exportMode: .png
        )
    }
}


#if os(macOS)
#endif
