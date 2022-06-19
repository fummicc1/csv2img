//
//  Csv2ImageAppApp.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import CoreData

#if os(macOS)
typealias Application = NSApplication
#elseif os(iOS)
typealias Application = UIApplication
#endif

@main
struct Csv2ImageAppApp: App {

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "Csv2Img")
        let description = NSPersistentStoreDescription()
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                print(error)
                assertionFailure(error.localizedDescription)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(
                    \.managedObjectContext, container.viewContext
                )
        }
        .commands {
            SidebarCommands()
        }
    }
}
