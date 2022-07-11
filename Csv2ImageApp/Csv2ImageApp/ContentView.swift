//
//  ContentView.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import Csv2Img
import CoreData
import PDFKit


struct ContentView: View {

    @Environment(\.managedObjectContext) var context

    var body: some View {
        #if os(iOS)
        VStack { }
        #elseif os(macOS)
        macOS_ContentView(historyModel: HistoryModel(context: context))
        #endif
    }
}
