//
//  Csv2ImageAppApp.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI

#if os(macOS)
typealias Application = NSApplication
#elseif os(iOS)
typealias Application = UIApplication
#endif

@main
struct Csv2ImageAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
