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
                    ChallengeView()
                }
                .tabItem {
                    Label("Challenge", systemImage: "star.fill")
                }
            }
            .tint(.nbAccent)
        }
    }
}
