//
//  iOS_ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/07/11.
//


#if os(iOS)
import SwiftUI
import Csv2Img
import UIKit

//
//struct iOS_ContentView: View {
//
//    @State private var error: CsvImageAppError?
//    @State private var networkURL: String = ""
//    @State private var showNetworkFileImporter: Bool = false
//    @State private var showFileImporter: Bool = false
//    @State private var csv: Csv?
//    @State private var completeSavingFile: Bool = false
//    @State private var savedOutputFileURL: URL?
//    @State private var contentMode: ContentMode = .create
//    @State private var exportType: Csv.ExportType = .pdf
//    @StateObject var historyModel: HistoryModel
//    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
//
//    var body: some View {
//        NavigationView {
//        }
//        .toolbar {
//            ToolbarItemGroup(placement: ToolbarItemPlacement.navigation) {
//                HStack {
//                    if exportType == .png {
//                        Text("Export as PNG")
//                            .frame(width: 120)
//                    } else {
//                        Text("Export as PDF")
//                            .frame(width: 120)
//                    }
//                    Toggle("", isOn: Binding<Bool>(
//                        get: {
//                            if exportType == .png {
//                                return true
//                            } else if exportType == .pdf {
//                                return false
//                            }
//                            return false
//                        }, set: { newValue in
//                            if newValue {
//                                exportType = .png
//                            } else {
//                                exportType = .pdf
//                            }
//                        }
//                    )).toggleStyle(SwitchToggleStyle())
//                    Button {
//                        showFileImporter = true
//                    } label: {
//                        Text("Choose from Computer")
//                            .frame(width: 200)
//                    }
//                    Button {
//                        showNetworkFileImporter = true
//                    } label: {
//                        Text("Choose from Network")
//                            .frame(width: 200)
//                    }
//                }
//            }
//            ToolbarItemGroup(placement: getToolBarItemPlacement()) {
//                if csv != nil {
//                    Button {
//                        let config = CsvConfig(context: context)
//                        // TODO: Customizable config
//                        let fontSize = 12
//                        config.fontSize = Int32(fontSize)
//                        config.separator = ","
//                        let output = CsvOutput(context: context)
//                        output.config = config
//                        output.raw = csv?.rawString
//                        output.generatedAt = Date()
//                        guard let data = csv?.generate(
//                            fontSize: CGFloat(fontSize),
//                            exportType: exportType
//                        ) else {
//                            return
//                        }
//                        output.png = data
//                        do {
//                            try context.save()
//                        } catch {
//                            self.error = .underlying(error)
//                        }
//                        let activityVC = UIActivityViewController(
//                            activityItems: [UIImage(data: data)!],
//                            applicationActivities: nil
//                        )
//                        UIApplication.shared.connectedScenes
//                            .filter({ $0.activationState == .foregroundActive })
//                            .compactMap({ $0 as? UIWindowScene })
//                            .compactMap({ $0.windows.first })
//                            .first?.rootViewController?
//                            .present(
//                                activityVC,
//                                animated: true,
//                                completion: nil
//                            )
//                    } label: {
//                        Text("Save")
//                            .foregroundColor(Color(nsColor: .windowBackgroundColor))
//                    }
//                    .frame(width: 64)
//                    .background(Color.accentColor)
//                    .cornerRadius(12)
//                }
//            }
//        }
//        .fileImporter(
//            isPresented: $showFileImporter,
//            allowedContentTypes: [.commaSeparatedText]
//        ) { result in
//            showFileImporter = false
//            switch result {
//            case .success(let url):
//                do {
//                    self.csv = try Csv.fromFile(url)
//                } catch {
//                    print(error.localizedDescription)
//                    self.error = .underlying(error)
//                }
//            case .failure(let error):
//                self.error = .underlying(error)
//            }
//        }
//        .alert(error?.message ?? "",
//               isPresented: Binding(
//                get: {
//                    error != nil
//                },
//                set: { _, __ in }
//               )
//        ) {
//            Button {
//                error = nil
//            } label: {
//                Text("Close")
//            }
//        }
//        .onAppear {
//            historyModel.onAppear()
//        }
//    }
//
//
//    private func getToolBarItemPlacement() -> ToolbarItemPlacement {
//        return .bottomBar
//    }
//
//}
//


#endif
