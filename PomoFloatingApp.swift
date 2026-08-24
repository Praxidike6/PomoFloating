import SwiftUI

@main
struct PomoFloatingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    configureFloatingWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
    
    private func configureFloatingWindow() {
        if let window = NSApplication.shared.windows.first {
            window.level = .floating
            window.isMovableByWindowBackground = true
            
            // Keep window transparent so dark UI dictates corners
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = false
            
            window.styleMask.insert([.fullSizeContentView, .titled])
            window.styleMask.remove(.resizable)
            
            // Show standard traffic light buttons on the dark header
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = false
            window.standardWindowButton(.zoomButton)?.isHidden = false
            
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
