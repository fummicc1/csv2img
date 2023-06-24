//
//  CsvBuilderExampleApp.swift
//  CsvBuilderExample
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import SwiftUI

@main
struct CsvBuilderExampleApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Text("Example 1")
                    }
                SecondContentView()
                    .tabItem {
                        Text("Example 2")
                    }
            }
        }
    }
}
