import SwiftUI
import AppKit

@main
struct RestxApp: App {
    private var config = Config.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(config)
                .preferredColorScheme(.dark)
        }
        
        Settings {
            SettingsView()
                .environmentObject(config)
                .preferredColorScheme(.dark)
        }
    }
}
