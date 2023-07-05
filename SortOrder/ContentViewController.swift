//
//  ContentViewController.swift
//  SortOrder
//
//  Created by Brian Kim on 6/7/2023.
//

import Foundation
import CoreData

final class ContentViewController {
    static let shared = ContentViewController()
    private var persistence = PersistenceController.shared
    
    func fetchHighestIndex() throws -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            let item = try self.persistence.container.viewContext.fetch(request)
            return item.first!
        } catch {
            return nil
        }
    }
}
