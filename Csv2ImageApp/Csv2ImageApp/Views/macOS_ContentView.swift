//
//  macOS_ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/07/11.
//


#if os(macOS)
import SwiftUI
import CoreData
import Csv2Img
import AppKit
import PDFKit


struct macOS_ContentView: View {
    @State private var error: CsvImageAppError?
    @State private var networkURL: String = ""
    @State private var showNetworkFileImporter: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?
    @State private var completeSavingFile: Bool = false
    @State private var savedOutputFileURL: URL?
    @State private var contentMode: ContentMode = .create
    @State private var exportType: Csv.ExportType = .pdf
    @StateObject var historyModel: HistoryModel
    @Environment(\.managedObjectContext) var context

    var body: some View {
        NavigationView {
            if case ContentMode.history(let history) = contentMode {
                if let raw = history.raw,
                   let csv = Csv.fromString(raw),
                   let config = history.config {
                    if let out = try? csv.generate(
                        fontSize: CGFloat(config.fontSize),
                        exportType: self.exportType
                    ) {
                        if exportType == .png, let img = out.base as! CGImage? {
                            CsvViewer(img: img)
                        } else if exportType == .pdf, let pdf = out.base as! PDFDocument? {
                            PdfDocumentView(document: pdf)
                        } else {
                            EmptyView()
                        }
                    }
                }
            } else {
                VStack {
                    if showNetworkFileImporter {
                        HStack {
                            TextField("Input URL", text: $networkURL)
                            Button("OK") {
                                if let url = URL(string: networkURL) {
                                    do {
                                        self.csv = try Csv.fromURL(url)
                                        showNetworkFileImporter = false
                                    } catch {
                                        self.error = .underlying(error)
                                    }
                                } else {
                                    self.error = CsvImageAppError.invalidNetworkURL(url: networkURL)
                                }
                            }
                        }
                        .padding()
                    }
                    if let csv = csv, let out = try? csv.generate(fontSize: 12, exportType: exportType) {
                        HStack {
                            Spacer()
                            VStack {
                                Text("Output").font(.title3).bold()
                                if exportType == .png, let img = out.base as! CGImage? {
                                    CsvViewer(img: img)
                                } else if exportType == .pdf, let pdf = out.base as! PDFDocument? {
                                    PdfDocumentView(document: pdf)
                                } else {
                                    EmptyView()
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    }
                }
            }
        }
        .toolbar {
            toolBar()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText]
        ) { result in
            showFileImporter = false
            switch result {
            case .success(let url):
                do {
                    self.csv = try Csv.fromFile(url)
                } catch {
                    print(error.localizedDescription)
                    self.error = .underlying(error)
                }
            case .failure(let error):
                self.error = .underlying(error)
            }
        }
        .alert(error?.message ?? "",
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
                Text("Close")
            }
        }
        .onAppear {
            historyModel.onAppear()
        }
    }

    private var hisoties: some View {
        Section("Histories") {
            ForEach(historyModel.histories) { (history: CsvOutput) in
                if let generatedAt = history.generatedAt {
                    Button {
                        contentMode = .history(history)
                    } label: {
                        Text(generatedAt, style: .date)
                    }

                }
            }
        }
    }

    private func getToolBarItemPlacement() -> ToolbarItemPlacement {
        return .principal
    }

    @ToolbarContentBuilder
    private func toolBar() -> some ToolbarContent {
        ToolbarItemGroup(placement: ToolbarItemPlacement.navigation) {
            AnyView(
                HStack {
                    if exportType == .png {
                        Text("Export as PNG")
                            .frame(width: 120)
                    } else {
                        Text("Export as PDF")
                            .frame(width: 120)
                    }
                    Toggle("", isOn: Binding<Bool>(
                        get: {
                            if exportType == .png {
                                return true
                            } else if exportType == .pdf {
                                return false
                            }
                            return false
                        }, set: { newValue in
                            if newValue {
                                exportType = .png
                            } else {
                                exportType = .pdf
                            }
                        }
                    )).toggleStyle(SwitchToggleStyle())
                    Button {
                        showFileImporter = true
                    } label: {
                        Text("Choose from Computer")
                            .frame(width: 200)
                    }
                    Button {
                        showNetworkFileImporter = true
                    } label: {
                        Text("Choose from Network")
                            .frame(width: 200)
                    }
                }
            )
        }
        ToolbarItemGroup(placement: getToolBarItemPlacement()) {
            if csv != nil {
                AnyView(
                    Button {
                        let config = CsvConfig(context: context)
                        // TODO: Customizable config
                        let fontSize = 12
                        config.fontSize = Int32(fontSize)
                        config.separator = ","
                        let output = CsvOutput(context: context)
                        output.config = config
                        output.raw = csv?.rawString
                        output.generatedAt = Date()
                        let panel = NSSavePanel()
                        panel.allowedContentTypes = [exportType.utType]
                        panel.begin { response in
                            switch response {
                            case .OK:
                                if let url = panel.url {
                                    let data = csv?.write(to: url)
                                    completeSavingFile = data != nil
                                    output.png = data
                                    do {
                                        try context.save()
                                    } catch {
                                        self.error = .underlying(error)
                                    }
                                }
                            default:
                                break
                            }
                        }
                    } label: {
                        Text("Save")
                            .foregroundColor(Color(nsColor: .windowBackgroundColor))
                    }
                        .frame(width: 64)
                        .background(Color.accentColor)
                        .cornerRadius(12)
                )
            }
        }
    }
}
#endif
