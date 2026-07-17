import SwiftUI

@main
struct Anime101App: App {
    @StateObject private var projectStore = ProjectStore()

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(projectStore)
        }
    }
}
