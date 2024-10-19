//
//  String+ExTests.swift
//  Csv2Img
//
//  Created by Fumiya Tanaka on 2024/10/19.
//

import XCTest

@testable import Csv2ImgCore

class StringExtensionTests: XCTestCase {
    func testGetSize() throws {
        let sut = "Hello World"
        let fontSize: CGFloat = 12

        // Because font system is different between iOS and macOS,
        // calculation logic might be different and result font size differs.
        #if os(iOS)
            let expected = CGSize(width: 61, height: 13)
        #elseif os(macOS)
            let expected = CGSize(width: 61, height: 12)
        #endif

        let actual = sut.getSize(fontSize: fontSize)
        XCTAssertEqual(actual, expected)
    }
}
