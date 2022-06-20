//
//  ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img
import CoreData


enum CsvImageAppError: Swift.Error {
    case invalidNetworkURL(url: String)
    case outputFileNameIsEmpty
    case underlying(Error)

    var message: String {
        switch self {
        case .invalidNetworkURL(let url):
            return "Invalid URL: \(url)"
        case .outputFileNameIsEmpty:
            return "Empty Output FileName"
        case .underlying(let error):
            return "\(error)"
        }
    }
}

enum ContentMode {
    case create
    case history(CsvOutput)
}

struct ContentView: View {

    @State private var error: CsvImageAppError?
    @State private var networkURL: String = ""
    @State private var showNetworkFileImporter: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?
    @State private var completeSavingFile: Bool = false
    @State private var savedOutputFileURL: URL?
    @State private var contentMode: ContentMode = .create
    @StateObject var historyModel: HistoryModel
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext

    var body: some View {
        NavigationView {
#if os(macOS)
            List {
                Button {
                    contentMode = .create
                } label: {
                    Label("Create", systemImage: "plus")
                }

                ForEach(histories) { (history: CsvOutput) in
                    if let generatedAt = history.generatedAt {
                        Button {
                            contentMode = .history(history)
                        } label: {
                            Text(generatedAt, style: .date)
                        }

                    }
                }
            }
#endif


#if os(iOS)
#elseif os(macOS)
            if case ContentMode.history(let history) = contentMode {
                if
                    let raw = history.raw,
                    let csv = Csv.fromString(raw),
                    let config = history.config,
                    let img = csv.cgImage(fontSize: CGFloat(config.fontSize)) {
                    CsvViewer(img: img)
                }
            } else {
                GeometryReader { proxy in
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
                        if let csv = csv, let img = csv.cgImage(fontSize: 12) {
                            HStack {
                                Spacer()
                                VStack {
                                    Text("Output Image")
                                        .font(.title3)
                                        .bold()
                                    CsvViewer(img: img)
                                }
                                .padding()
                                Spacer()
                            }
                        }
                    }
                }
            }
#endif
        }
        .toolbar {
            ToolbarItemGroup(placement: getToolBarItemPlacement()) {
                Button {
                    showFileImporter = true
                } label: {
                    Text("from Device.")
                }
                Button {
                    showNetworkFileImporter = true
                } label: {
                    Text("from Network.")
                }

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
#if os(macOS)
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.png]
                    panel.begin { response in
                        switch response {
                        case .OK:
                            if let url = panel.url {
                                let ok = csv?.write(to: url)
                                completeSavingFile = ok ?? false
                                output.png = csv?.pngData(fontSize: CGFloat(fontSize))
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
#elseif os(iOS)
                    guard let data = csv?.pngData(fontSize: CGFloat(fontSize)) else {
                        return
                    }
                    output.png = data
                    do {
                        try context.save()
                    } catch {
                        self.error = .underlying(error)
                    }
                    let activityVC = UIActivityViewController(
                        activityItems: [UIImage(data: data)!],
                        applicationActivities: nil
                    )
                    UIApplication.shared.connectedScenes
                        .filter({ $0.activationState == .foregroundActive })
                        .compactMap({ $0 as? UIWindowScene })
                        .compactMap({ $0.windows.first })
                        .first?.rootViewController?
                        .present(
                            activityVC,
                            animated: true,
                            completion: nil
                        )
#endif
                } label: {
                    Text("Save")
                }
                .buttonStyle(.borderedProminent)
                .disabled(csv == nil)
            }
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
    }


    private func getToolBarItemPlacement() -> ToolbarItemPlacement {
        var placement: ToolbarItemPlacement = .primaryAction
#if os(iOS)
        placement = .bottomBar
#endif
        return placement
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
