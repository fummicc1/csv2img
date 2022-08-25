//
//  ContentView.swift
//  CsvBuilderExample
//
//  Created by Fumiya Tanaka on 2022/08/25.
//

import SwiftUI
import CsvBuilder

struct ContentView: View {

    @State private var composition: ExampleComposition = .init()
    @State private var image: CGImage?

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
            if let image = image {
                Image(nsImage: NSImage(cgImage: image, size: CGSize(width: image.width, height: image.height)))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .padding()
        .task {
            composition.ages.append("99")
            composition.names.append("Yamada")
            let csv = try! composition.build()
            let data = try! await csv.generate(fontSize: 20, exportType: .png)
            self.image = data.base as! CGImage
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
