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
    
    func move(item: Item, origin: Int, destination: Int) {
        guard origin != destination else { return }
        
        print("Origin: \(origin)")
        print("Destination: \(destination)")
        
        if destination == 0 {
            if let firstItem = fetchHighestIndex() {
                item.index = assignIndex(end: firstItem.index)
            }
        } else if origin > destination {
            // `move` will always insert it below the destination when trying to move
            if let parentNeighbourIndex = fetchIndex(at: destination),
               let descNeighbourIndex = fetchDescendingNeighbourIndex(at: destination) {
                item.index = assignIndex(start: parentNeighbourIndex, end: descNeighbourIndex)
            }
            // there'll be a bug where if you move the items enough times, then random can't do its job
        } else if origin < destination {
            if let firstDescNeighbour = fetchItem(at: destination) {
                if let secDescNeighbourIndex = fetchDescendingNeighbourIndex(at: destination) {
                    item.index = assignIndex(start: firstDescNeighbour.index, end: secDescNeighbourIndex)
                } else if let parentNeighbourIndex = fetchIndex(at: destination - 1) {
                    firstDescNeighbour.index = assignIndex(start: parentNeighbourIndex, end: 0)
                    item.index = 0
                }
            }
        }
    }
    
    func fetchHighestIndex() -> Item? {
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
    
    func fetchDescendingNeighbourIndex(at destination: Int) -> Int64? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.fetchOffset = destination
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item.index
        } catch {
            return nil
        }
    }
    
    func fetchItem(at destination: Int) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.fetchOffset = destination - 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item
        } catch {
            return nil
        }
    }
    
    func fetchIndex(at destination: Int) -> Int64? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.fetchOffset = destination - 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item.index
        } catch {
            return nil
        }
    }
    
    /// This is a dumb function. We need to write higher level functions for validation.
    private func assignIndex(start: Int64 = -99999, end: Int64) -> Int64 {
        return Int64.random(in: start...end)
    }
}
