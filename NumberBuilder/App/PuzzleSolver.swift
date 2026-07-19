import Foundation
import Observation
import NumberBuilderKit

/// Runs a dice/target pair through `SolverEngine`, tracking progress as an `@Observable` object
/// so a view can show a live count while it works. Shared so Solve's input-form flow and
/// Challenge's "show every solution for this fixed puzzle" flow both drive the exact same
/// solving/progress behavior instead of two copies that could drift apart.
@Observable
@MainActor
final class PuzzleSolver {
    private let engine = SolverEngine()
    private var solveTask: Task<Void, Never>?

    private(set) var isSolving = false
    private(set) var progressCount = 0
    private(set) var solutions: [Solution]?

    /// Starts (or restarts) solving `dice`/`target`. `onFinished` fires once, only if the search
    /// actually completes rather than getting cancelled by a later `solve`/`cancel` call.
    func solve(dice: [Int], target: Int, onFinished: @escaping ([Solution]) -> Void = { _ in }) {
        solveTask?.cancel()
        solutions = nil
        isSolving = true
        progressCount = 0

        let configuration = SolverConfiguration(dice: dice, target: target)
        let engine = engine
        solveTask = Task {
            for await event in await engine.solve(configuration) {
                switch event {
                case .progress(let count):
                    self.progressCount = count
                case .finished(let results):
                    self.solutions = results
                    self.isSolving = false
                    onFinished(results)
                }
            }
        }
    }

    func cancel() {
        solveTask?.cancel()
        isSolving = false
        solutions = nil
    }
}
