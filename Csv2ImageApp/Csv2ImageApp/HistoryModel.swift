//
//  HistoryModel.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/20.
//

import Foundation
import CoreData

class HistoryModel: ObservableObject {
    let context: NSManagedObjectContext

    @MainActor @Published var histories: [CsvOutput] = []

    init(context: NSManagedObjectContext) {
        self.context = context

        NotificationCenter.default.addObserver(
            forName: NSManagedObjectContext.didChangeObjectsNotification,
            object: context.persistentStoreCoordinator,
            queue: nil
        ) { notification in
            if let added = notification.userInfo?[NSInsertedObjectsKey] as? Set<CsvOutput> {
                Task { @MainActor in
                    self.histories.append(contentsOf: added)
                }
            }
            if let deleted = notification.userInfo?[NSDeletedObjectsKey] as? Set<CsvOutput> {
                Task { @MainActor in
                    self.histories.removeAll(where: { obj in
                        deleted.contains(where: { $0.objectID == obj.objectID })
                    })

                }
            }
            if let updated = notification.userInfo?[NSUpdatedObjectsKey] as? Set<CsvOutput> {
                for updatedElement in updated {
                    Task {
                        if let i = await self.histories.firstIndex(where: { $0.objectID == updatedElement.objectID }) {
                            await MainActor.run(body: {
                                self.update(index: i, value: updatedElement)
                            })
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func update(index: Int, value: CsvOutput) {
        self.histories[index] = value
    }

    func save() throws {
        try context.save()
    }


}
