//
//  CsvConfig+CoreDataProperties.swift
//  Csv2ImageApp
//
//  Created by Fumiya Tanaka on 2022/06/20.
//
//

import Foundation
import CoreData


extension CsvConfig {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CsvConfig> {
        return NSFetchRequest<CsvConfig>(entityName: "CsvConfig")
    }

    @NSManaged public var separator: String?
    @NSManaged public var fontSize: Int32

}

extension CsvConfig : Identifiable {

}
