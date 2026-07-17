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

    func rollDice() {
        diceFaces = DiceRoller.roll()
        solutions = nil
        hasSolved = false
        AppLogger.solve.debug("Rolled dice: \(self.diceFaces)")
    }

    func calculate() {
        guard let target else { return }
        solveTask?.cancel()
        solutions = nil
        hasSolved = false
        isSolving = true
        progressCount = 0
        AppLogger.solve.debug("Calculating for dice \(self.diceFaces), target \(target)")

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
                    AppLogger.solve.debug("Found \(results.count) solutions")
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
