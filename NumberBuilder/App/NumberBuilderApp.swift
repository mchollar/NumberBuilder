import SwiftUI

@main
struct NumberBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    SolveView()
                }
                .tabItem {
                    Label("Explore", systemImage: "die.face.5.fill")
                }

                NavigationStack {
                    PracticeView()
                }
                .tabItem {
                    Label("Challenge", systemImage: "pencil.and.ruler.fill")
                }
            }
            .tint(.nbAccent)
        }
    }
}
