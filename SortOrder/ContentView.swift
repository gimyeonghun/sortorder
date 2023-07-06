//
//  ContentView.swift
//  SortOrder
//
//  Created by Brian Kim on 6/7/2023.
//
// https://www.appsdissected.com/order-core-data-entities-maximum-speed/

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.index, ascending: true), NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>
    
    private let controller = ContentViewController.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    Text("\(item.index). Item at \(item.timestamp!, formatter: itemFormatter)")                }
                .onMove(perform: move)
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
            newItem.index = 0 // it'll always be at the bottom of the list
            
            checkPreviousNeighbour(newItem)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func checkPreviousNeighbour(_ item: Item) {
        if let neighbour = fetchPreviousNeighbour(item) {
            if neighbour.index >= item.index {
                if let previousNeighbour = fetchPreviousNeighbour(neighbour) {
                    neighbour.index = Int64.random(in: previousNeighbour.index...item.index)
                    if neighbour.index == 0 {
                        print("check here") // also a problem
                        while neighbour.index == 0 {
                            neighbour.index = Int64.random(in: previousNeighbour.index...item.index)
                        }
                    }
                    
                } else {
                    neighbour.index = Int64.random(in: -99999...item.index)
                    print("this is getting called")
                }
                print("Changed Neighbour Index: \(neighbour.index)")
            } else {
                // buggy
                print("Neighbour Index: \(neighbour.index) vs \(item.index)")
            }
        } else {
            print("Nothing got called")
        }
    }
    // There's a bug where you have to wait
    
    private func fetchPreviousNeighbour(_ item: Item) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        guard let fetch = try? viewContext.fetch(request),
              let index = fetch.firstIndex(of: item),
              index > 0 else { return nil }
        let neighbour = fetch[index - 1]
        return neighbour
    }
    
    private func fetchForwardNeighbour(_ item: Item) -> Item? {
        let request = NSFetchRequest<Item>(entityName: "Item")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Item.index, ascending: true)]
        guard let fetch = try? viewContext.fetch(request),
              let index = fetch.firstIndex(of: item),
              index + 1 != fetch.count else { return nil }
        let neighbour = fetch[index + 1]
        return neighbour
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        let origin = source.map { $0 }.first!
        let item = items[origin]

        controller.move(item: item, origin: origin, destination: destination)
        
//        if destination == 0 {
//            item.index = Int64.random(in: -99999...items.first!.index)
//        } else if destination == items.count {
//            item.index = 0
//            checkPreviousNeighbour(item)
//        } else if origin > destination { // going down
//            if let neighbour = fetchPreviousNeighbour(item),
//               let previousNeigbour = fetchPreviousNeighbour(neighbour) {
//                item.index = Int64.random(in: previousNeigbour.index...neighbour.index)
//            }
//        } else if origin < destination { // going up
//            if let neighbour = fetchForwardNeighbour(item),
//               let forwardNeighbour = fetchForwardNeighbour(neighbour) {
//                item.index = Int64.random(in: neighbour.index...forwardNeighbour.index)
//            }
//        }
        

//        var objects = items.map { $0 }
//        objects.move(fromOffsets: source, toOffset: destination)
//        for reverseIndex in stride(from: objects.count - 1, to: 0, by: -1) {
//            objects[reverseIndex].index = Int64(reverseIndex)
//        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}

enum State {
    case top
    case inBetween
    case bottom
}
