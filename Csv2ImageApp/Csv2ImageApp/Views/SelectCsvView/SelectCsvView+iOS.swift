//
//  SelectCsvView+iOS.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/08/07.
//

import SwiftUI

#if os(iOS)
    struct SelectCsvView_iOS: View {

        @StateObject var model: SelectCsvModel

        var body: some View {
            NavigationView {
                Form {
                    Section(header: Text("Select CSV File")) {
                        Button(action: {
                            Task {
                                await model.selectFileOnDisk()
                            }
                        }) {
                            Label("Choose File", systemImage: "doc")
                        }
                    }

                    Section(header: Text("Or Enter URL")) {
                        HStack {
                            TextField("https://example.com/file.csv", text: $model.networkUrlText)
                            if !model.networkUrlText.isEmpty {
                                Button(action: {
                                    model.networkUrlText = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("Load from URL") {
                            Task {
                                await model.selectFileOnTheInternet()
                            }
                        }
                    }

                    Section(footer: Text("Saved data is stored in Folder App.").font(.footnote)) {
                        Button(action: {
                            model.openFolderApp()
                        }) {
                            Label("Open Folder App", systemImage: "folder")
                        }
                    }
                }
                .navigationTitle("Select CSV")
            }
            .alert(
                "Error", isPresented: $model.error.isNotNil(),
                actions: {
                    Button("Close") {
                        model.error = nil
                    }
                },
                message: {
                    Text(model.error ?? "")
                })
        }
    }

    struct SelectCsvView_iOS_Previews: PreviewProvider {
        static var previews: some View {
            SelectCsvView_iOS(model: SelectCsvModel())
        }
    }
#endif
