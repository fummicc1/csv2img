//
//  ContentView.swift
//  CsvBuilderExample
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import SwiftUI
import CsvBuilder

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            let example = ExampleComposition()
            try! CsvBuilder.inject(composition: example)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
