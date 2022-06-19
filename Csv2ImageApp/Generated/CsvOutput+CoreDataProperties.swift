//
//  CsvOutput+CoreDataProperties.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/20.
//
//

import Foundation
import CoreData


extension CsvOutput {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CsvOutput> {
        return NSFetchRequest<CsvOutput>(entityName: "CsvOutput")
    }

    @NSManaged public var raw: String?
    @NSManaged public var png: Data?
    @NSManaged public var config: CsvConfig?

}

extension CsvOutput : Identifiable {

}
