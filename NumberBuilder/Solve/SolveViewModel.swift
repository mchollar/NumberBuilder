import Foundation
import Observation
import NumberBuilderKit

@Observable
@MainActor
final class SolveViewModel {
    private let engine = SolverEngine()
    private var solveTask: Task<Void, Never>?

    var diceFaces: [Int] = [1, 2, 3]
    var targetText: String = ""
    var isSolving = false
    var progressCount = 0
    var solutions: [Solution]?
    var hasSolved = false

    var target: Int? { Int(targetText) }

    var canCalculate: Bool {
        guard let target, target > 0 else { return false }
        return !isSolving
    }

    /// Matches the shipped app's house rule: re-rolls until at most one die shows a 1.
    func rollDice() {
        var faces: [Int]
        repeat {
            faces = (0..<3).map { _ in Int.random(in: 1...6) }
        } while faces.filter({ $0 == 1 }).count > 1
        diceFaces = faces
        solutions = nil
        hasSolved = false
    }

    func calculate() {
        guard let target else { return }
        solveTask?.cancel()
        solutions = nil
        hasSolved = false
        isSolving = true
        progressCount = 0

        let configuration = SolverConfiguration(dice: diceFaces, target: target)
        let engine = engine
        solveTask = Task {
            for await event in await engine.solve(configuration) {
                switch event {
                case .progress(let count):
                    self.progressCount = count
                case .finished(let results):
                    self.solutions = results
                    self.isSolving = false
                    self.hasSolved = true
                }
            }
        }
    }

    func resetForNewRoll() {
        solveTask?.cancel()
        isSolving = false
        solutions = nil
        hasSolved = false
    }
}
