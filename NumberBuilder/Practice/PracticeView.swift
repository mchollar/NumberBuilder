import SwiftUI

// Placeholder for the tab shell (milestone 4 of the Solve/Practice plan) -- the real
// difficulty picker, puzzle display, and tap-to-build workspace land in the next milestone.
struct PracticeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.ruler.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("Practice mode is coming soon.")
                .font(.nbNumber(18))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.nbBackground.ignoresSafeArea())
        .navigationTitle("Practice")
    }
}

#Preview("Practice") {
    NavigationStack {
        PracticeView()
    }
}
