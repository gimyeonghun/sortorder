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
    
    func add(item: Item) {
        item.index = 0
        var fetch = fetchLowestItems()
        if fetch.count > 1 {
            fetch.removeFirst() // discard the first item because it'll always be the one that we just added
            let lowest = fetch.removeFirst()
            if lowest.index >= 0 {
                print(fetch.count)
                if fetch.count == 1 {
                    let neighbour = fetch.removeFirst()
                    lowest.index = assignIndex(start: neighbour.index, end: 0)
                } else {
                    lowest.index = assignIndex(end: 0)
                }
            }
        }
    }
    
    func move(item: Item, origin: Int, destination: Int) {
        print("Origin: \(origin)")
        print("Destination: \(destination)")
        
        if destination == 0 {
            if let firstItem = fetchHighestIndex() {
                item.index = assignIndex(end: firstItem.index)
            }
        } else if origin > destination {
            // `move` will always insert it below the destination when trying to move
            if let parentNeighbour = fetchItem(at: destination),
               let descNeighbour = fetchDescendingNeighbour(at: destination) {
                item.index = assignIndex(start: parentNeighbour.index, end: descNeighbour.index)
                validate([descNeighbour, item, parentNeighbour])
            }
            // there'll be a bug where if you move the items enough times, then random can't do its job
        } else if origin < destination {
            if let firstDescNeighbour = fetchItem(at: destination) {
                if let secDescNeighbour = fetchDescendingNeighbour(at: destination) {
                    item.index = assignIndex(start: firstDescNeighbour.index, end: secDescNeighbour.index)
                    validate([secDescNeighbour, item, firstDescNeighbour])
                } else if let parentNeighbourIndex = fetchIndex(at: destination - 1) {
                    firstDescNeighbour.index = assignIndex(start: parentNeighbourIndex, end: 0)
                    item.index = 0
                }
            }
        }
    }
    
    private func fetchHighestIndex() -> Item? {
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
    
    private func fetchLowestItems() -> [Item] {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "%K <= 0", #keyPath(Item.index))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: false), NSSortDescriptor(keyPath: \Item.timestamp, ascending: false)]
        request.fetchLimit = 3
        do {
            let items = try self.persistence.container.viewContext.fetch(request)
            return items
        } catch {
            return []
        }
    }
    
    private func fetchDescendingNeighbour(at destination: Int) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.fetchOffset = destination
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item
        } catch {
            return nil
        }
    }
    
    private func fetchDescendingNeighbour(below index: Int64) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "%K > %ld", #keyPath(Item.index), index)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item
        } catch {
            return nil
        }
    }
    
    private func fetchParentNeighbour(above index: Int64) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.predicate = NSPredicate(format: "%K <= %ld", #keyPath(Item.index), index)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        request.fetchLimit = 1
        do {
            guard let item = try self.persistence.container.viewContext.fetch(request).first else { return nil }
            return item
        } catch {
            return nil
        }
    }
    
    private func fetchItem(at destination: Int) -> Item? {
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
    
    private func fetchIndex(at destination: Int) -> Int64? {
        guard let item = try? fetchItem(at: destination) else { return nil }
        return item.index
    }
    
    /// Checks whether there's enough space for the items to be differeniated
    private func validate(_ items: [Item]) {
        recalculateBounds(items)
        checkUniqueness(items)
        cleanUp()
    }
    
    private func recalculateBounds(_ items: [Item]) {
        if let upperBound = items.max(by: { $0.index < $1.index }),
           let lowerBound = items.min(by: { $0.index < $1.index }) {
            
            if abs(upperBound.index - lowerBound.index) < 10 {
                var newUpperBoundIndex = fetchParentNeighbour(above: upperBound.index)?.index ?? -99999
                if abs(newUpperBoundIndex - upperBound.index) < 100 {
                    newUpperBoundIndex = -99999
                }
                var newLowerBound = fetchDescendingNeighbour(below: lowerBound.index)?.index ?? 0
                if abs(lowerBound.index - newLowerBound) < 100 {
                    newLowerBound = fetchDescendingNeighbour(below: newLowerBound)?.index ?? 0
                }
                
                let range = abs(newUpperBoundIndex - newLowerBound) / 3
                print("range is \(range); lower: \(newLowerBound) - upper: \(newUpperBoundIndex)")
                print("Starting from: \(newLowerBound)")
                
                for index in stride(from: newLowerBound, through: newUpperBoundIndex, by: Int64.Stride(range)) {
                    items[Int(index)].index = -range * index
                }
                
                print("Finishing at: \(newUpperBoundIndex)")
                
            }
        }
    }
    
    private func checkUniqueness(_ items: [Item]) {
        let request = NSFetchRequest<Item>(entityName: "Item")
      
        for item in items {
            request.predicate = NSPredicate(format: "%K == %ld AND %K != %@", #keyPath(Item.index), item.index, #keyPath(Item.timestamp), item.timestamp! as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
            request.fetchLimit = 1
            if let similarItem = try? self.persistence.container.viewContext.fetch(request).first,
               let upperBound = fetchParentNeighbour(above: item.index),
               let lowerBound = fetchDescendingNeighbour(below: item.index) {
                similarItem.index = Int64.random(in: similarItem.index...upperBound.index)
                item.index = Int64.random(in: lowerBound.index...similarItem.index)
            }
        }
    }
    
    private func cleanUp() {
        if let zeroIndexItem = fetchLowestItems().first {
            zeroIndexItem.index = 0
        }
    }
    
    /// This is a dumb function. We need to write higher level functions for validation.
    private func assignIndex(start: Int64 = -99999, end: Int64) -> Int64 {
        return Int64.random(in: start...end)
    }
}
