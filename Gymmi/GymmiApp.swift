//
//  GymmiApp.swift
//  Gymmi
//
//  Created by Ivan Kirsanov on 30.03.2025.
//

import SwiftUI

@main
struct GymmiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
