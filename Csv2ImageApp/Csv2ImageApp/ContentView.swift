//
//  ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img

struct ContentView: View {

    private let marker: ImageMakerType = ImageMaker(fontSize: 12)

    @State private var error: Error?
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?

    var body: some View {
        VStack {
            if let csv = csv, let data = marker.make(csv: csv) {
                
            }
        }.fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            switch result {
            case .success(let url):
                do {
                    self.csv = try Csv.fromFile(url)
                } catch {
                    self.error = error
                }
            case .failure(let error):
                self.error = error
            }
        }
        .alert("エラー",
               isPresented: Binding(
                get: {
                    error != nil
                },
                set: { _, __ in }
               )
        ) {
            Button {
                error = nil
            } label: {
                Text(error!.localizedDescription)
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
