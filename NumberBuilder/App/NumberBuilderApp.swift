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
                    Label("Solve", systemImage: "die.face.5.fill")
                }

                NavigationStack {
                    PracticeView()
                }
                .tabItem {
                    Label("Practice", systemImage: "pencil.and.ruler.fill")
                }
            }
            .tint(.nbAccent)
        }
    }
}
