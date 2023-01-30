// Created for swiftUI75029229 by 0x67 on 2023-01-30

import SwiftUI

@main
struct swiftUI75029229App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
