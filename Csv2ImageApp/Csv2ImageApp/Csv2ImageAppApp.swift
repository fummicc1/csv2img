//
//  Csv2ImageAppApp.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/07.
//

import SwiftUI
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
                assertionFailure("\(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.persistentController = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(
                    \.managedObjectContext, persistentController.viewContext
                )
        }
    }
}

class AppDelegate: Responder, ApplicationDelegate {
}
