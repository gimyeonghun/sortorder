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
    private let request = NSFetchRequest<Item>(entityName: "Item")
    
    func add(item: Item) {
        item.index = 0
        var fetch = fetchLowestItems()
        if fetch.count > 1 {
            fetch.removeFirst()
            let lowest = fetch.removeFirst()
            if lowest.index >= 0 {
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
            guard let firstItem = fetchHighestIndex() else { return }
            item.index = assignIndex(end: firstItem.index)
            cleanUp()
        } else if origin > destination {
            // `move` will always insert it below the destination when trying to move
            guard let parentNeighbour = fetchItem(at: destination),
                  let descNeighbour = fetchDescendingNeighbour(at: destination) else { return }
            item.index = assignIndex(start: parentNeighbour.index, end: descNeighbour.index)
            validate([descNeighbour, item, parentNeighbour])
        } else if origin < destination {
            guard let firstDescNeighbour = fetchItem(at: destination) else { return }
            if let secDescNeighbour = fetchDescendingNeighbour(at: destination) {
                item.index = assignIndex(start: firstDescNeighbour.index, end: secDescNeighbour.index)
                validate([secDescNeighbour, item, firstDescNeighbour])
            } else if let parentNeighbour = fetchItem(at: destination - 1) {
                firstDescNeighbour.index = assignIndex(start: parentNeighbour.index, end: 0)
                item.index = 0
            }
        }
    }
    
    private func fetchHighestIndex() -> Item? {
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

    /// Checks whether there's enough space for the items to be differeniated
    private func validate(_ items: [Item]) {
        recalculateBounds(items)
//        checkUniqueness(items)
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
                
                let range = abs(newUpperBoundIndex - newLowerBound)
                print("range is \(range); lower: \(newLowerBound) - upper: \(newUpperBoundIndex)")
                print("Starting from: \(newLowerBound)")
                
                for (index, item) in items.enumerated() {
                    let multiplier = range/5 * Int64(index+1)
                    item.index = newLowerBound - multiplier
                }
                
                print("Finishing at: \(newUpperBoundIndex)")
                
            }
        }
    }
    
    private func checkUniqueness(_ items: [Item]) {
        for item in items {
            request.predicate = NSPredicate(format: "%K == %ld AND %K != %@", #keyPath(Item.index), item.index, #keyPath(Item.timestamp), item.timestamp! as CVarArg)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
            request.fetchLimit = 1
            if let similarItem = try? self.persistence.container.viewContext.fetch(request).first,
               let upperBound = fetchParentNeighbour(above: item.index),
               let lowerBound = fetchDescendingNeighbour(below: item.index) {
                print(similarItem.index)
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
