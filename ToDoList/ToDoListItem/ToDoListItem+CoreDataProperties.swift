//
//  ToDoListItem+CoreDataProperties.swift
//  ToDoList
//
//  Created by Василий Тихонов on 26.08.2024.
//
//

import Foundation
import CoreData


extension ToDoListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoListItem> {
        return NSFetchRequest<ToDoListItem>(entityName: "ToDoListItem")
    }

    @NSManaged public var id: Int16
    @NSManaged public var todo: String?
    @NSManaged public var completed: Bool
    @NSManaged public var userId: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var title: String?


}

extension ToDoListItem : Identifiable {

}
