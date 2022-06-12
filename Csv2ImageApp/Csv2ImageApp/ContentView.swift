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

struct ContentView: View {

    @State private var error: CsvImageAppError?
    @State private var networkURL: String = ""
    @State private var showNetworkFileImporter: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var csv: Csv?
    @State private var completeSavingFile: Bool = false
    @State private var savedOutputFileURL: URL?


    var body: some View {
        GeometryReader { proxy in
            HStack {
                Spacer()
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
                        Text("Output Image")
                            .font(.title3)
                            .bold()
                        ScrollView {
                            Image(img, scale: 1, orientation: .up, label: Text("Output Image"))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: proxy.size.width * 0.8)
                        }
                    }
    #if os(macOS)
                    HStack {
                        actions()
                    }
    #elseif os(iOS)
                    VStack(spacing: 0) {
                        actions()
                    }
    #endif
                }
                Spacer()
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

    @ViewBuilder
    func actions() -> some View {
        Button {
            showFileImporter = true
        } label: {
            Text("Choose Csv File from Device.")
                .font(.body)
                .bold()
        }
        .buttonStyle(.bordered)
        .padding()

        Button {
            showNetworkFileImporter = true
        } label: {
            Text("Choose Csv File from Network.")
                .font(.body)
                .bold()
        }
        .buttonStyle(.bordered)
        .padding()
        Spacer()
        Button {
#if os(macOS)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            panel.begin { response in
                switch response {
                case .OK:
                    if let url = panel.url {
                        let ok = csv?.write(to: url)
                        completeSavingFile = ok ?? false
                    }
                default:
                    break
                }
            }
#elseif os(iOS)
            guard let data = csv?.pngData() else {
                return
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
            Text("Save Output Image.")
                .font(.body)
                .bold()
        }
        .buttonStyle(.borderedProminent)
        .disabled(csv == nil)
        .padding()

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
