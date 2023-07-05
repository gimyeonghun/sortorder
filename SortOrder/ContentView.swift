//
//  ContentView.swift
//  SortOrder
//
//  Created by Brian Kim on 6/7/2023.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.index, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

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
        
        print("The item of interest", item.index)
        
        if let neighbour = fetchPreviousNeighbour(item) {
            
            print("The preceding neighbour", neighbour.index)
            
            if neighbour.index == item.index {
                neighbour.index = -1000
//                if let previousNeighbour = fetchPreviousNeighbour(neighbour) {
//
//                    print("The previous neighbour index to all of this is \(previousNeighbour.index)")
//
//                    neighbour.index = (previousNeighbour.index + item.index) / 2
//
//                    print("Neighbour index changed to \(neighbour.index)")
//
//                } else {
//                    print("Changing neighbour index to -1000")
//                    neighbour.index = -1000
//                }
            }
        } else {
            print("Nothing got called")
        }
    }
    
    private func fetchPreviousNeighbour(_ item: Item) -> Item? {
        guard items.count > 0 else { return nil }
        let neighbour = items[0]
        return neighbour
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        print("Indices: \(source.map { $0 })")
        print("Destination: \(destination)")
        
        let item = items[source.first!]
        let object = items[destination]
        
        item.index = object.index - 100
        
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
