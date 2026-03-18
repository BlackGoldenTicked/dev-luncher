import SwiftUI

@main
struct IDEGoApp: App {
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var toolManager = ToolManager.shared
    
    init() {
        ProjectIndexManager.shared.start()
    }

    var body: some Scene {
        MenuBarExtra("IDEGo", systemImage: "terminal.fill") {
            ContentView()
                .environmentObject(settingsManager)
                .environmentObject(toolManager)
                .frame(width: 460, height: 500)
        }
        .menuBarExtraStyle(.window)
    }
}
