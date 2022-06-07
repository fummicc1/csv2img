//
//  ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img

enum CsvImageAppError: Swift.Error {
    case invalidNetworkURL(url: String)
}

struct ContentView: View {

    @State private var error: Error?
    @State private var networkURL: String = ""
    @State private var showNetworkFileImporter: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?

    var body: some View {
        GeometryReader { proxy in
            VStack {
                if showNetworkFileImporter {
                    HStack {
                        TextField("Input URL", text: $networkURL)
                        Button("OK") {
                            if let url = URL(string: networkURL) {
                                do {
                                    csv = try Csv.fromURL(url)
                                    showNetworkFileImporter = false
                                } catch {
                                    self.error = error
                                }
                            } else {
                                self.error = CsvImageAppError.invalidNetworkURL(url: networkURL)
                            }
                        }
                    }
                    .padding()
                }
                if let csv = csv, let img = csv.cgImage(fontSize: 12) {
                    Text("Output Image")
                        .font(.title)
                        .bold()
                    Image(img, scale: 1, orientation: .up, label: Text("Output Image"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                HStack {
                    Button {
                        showFileImporter = true
                    } label: {
                        Text("Choose Csv File from Local Computer.")
                            .font(.title3)
                            .bold()
                    }
                    .padding()

                    Button {
                        showNetworkFileImporter = true
                    } label: {
                        Text("Choose Csv File from Network.")
                            .font(.title3)
                            .bold()
                    }
                    .padding()
                    Spacer()
                    Button {
                        let panel = NSSavePanel()
                        panel.begin { response in
                            switch response {
                            case .OK:
                                if let url = panel.url {
                                    csv?.write(to: url)
                                }
                            default:
                                break
                            }
                        }
                    } label: {
                        Text("Save Output Image.")
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
        .alert("Error Occurred.",
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
                Text(String(describing: error))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
