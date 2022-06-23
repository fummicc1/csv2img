//
//  Csv2ImageAppApp.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
import CoreData


@main
struct Csv2ImageAppApp: App {

    @ApplicationDelegateAdaptor var appDelegate: AppDelegate

    var persistentController: NSPersistentContainer

    init() {
        let container = NSPersistentContainer(name: "Csv2Img")
        let description = NSPersistentStoreDescription()
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        description.setOption(
            true as NSNumber,
            forKey: "NSPersistentStoreRemoteChangeNotificationOptionKey"
        )
        description.shouldMigrateStoreAutomatically = true
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error {
                print(error)
                assertionFailure(error.localizedDescription)
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.persistentController = container
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                historyModel: HistoryModel(context: persistentController.viewContext)
            )
                .environment(
                    \.managedObjectContext, persistentController.viewContext
                )
        }
        .commands {
            SidebarCommands()
        }
    }
}

class AppDelegate: Responder, ApplicationDelegate {
}
