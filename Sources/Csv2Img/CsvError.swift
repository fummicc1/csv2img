//
//  CsvError.swift
//  
//
//  Created by Fumiya Tanaka on 2022/08/26.
//

import Foundation


extension Csv {

    /// `Error` related with Csv implmentation.
    public enum Error: Swift.Error {
        /// Specified network url is invalid or failed to download csv data.
        case invalidDownloadResource(url: String, data: Data)
        /// Specified local url is invalid (file may not exist. using incorrect `String.Encoding` Type).
        case invalidLocalResource(url: String, data: Data, encoding: String.Encoding)
        /// If file is not accessible due to security issue.
        case cannotAccessFile(url: String)
        /// given `exportType` is invalid.
        case invalidExportType(ExportType)
        /// Both columns and rows are empty
        case emptyData
        /// Csv denied execution because it is generating another contents.
        case workInProgress
        case underlying(Swift.Error?)
    }
}
