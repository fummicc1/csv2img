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
    let url: URL
    let urlType: FileURLType

    init(url: URL, urlType: FileURLType) {
        self.url = url
        self.urlType = urlType
    }
}


#if os(macOS)
#endif
