//
//  PromptAiTestApp.swift
//  PromptAiTest
//
//  Created by Rishi Cadambe on 12/2/23.
//

import SwiftUI

@main
struct PromptAiTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
