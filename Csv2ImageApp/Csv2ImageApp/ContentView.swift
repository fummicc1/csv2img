//
//  ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img

struct ContentView: View {

    @State private var error: Error?
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?

    var body: some View {
        GeometryReader { proxy in
            VStack {
                if let csv = csv, let img = csv.cgImage(fontSize: 12) {
                    Image(img, scale: 1, orientation: .up, label: Text("Output Image"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                HStack {
                    Button {
                        showFileImporter = true
                    } label: {
                        Text("Choose Csv File.")
                            .font(.title3)
                            .bold()
                    }
                    .padding()
                    Spacer()
                    Button {
                        showFileImporter = true
                    } label: {
                        Text("Choose Csv File.")
                            .font(.title3)
                            .bold()
                    }
                    .padding()
                }
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
                Text(error?.localizedDescription ?? "")
            }

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
