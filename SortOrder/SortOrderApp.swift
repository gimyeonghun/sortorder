//
//  SortOrderApp.swift
//  SortOrder
//
//  Created by Brian Kim on 6/7/2023.
//

import SwiftUI

@main
struct SortOrderApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
