import Foundation
import Observation
import NumberBuilderKit

@Observable
@MainActor
final class SolveViewModel {
    private let solver = PuzzleSolver()

    var diceFaces: [Int] = [1, 2, 3]
    var targetText: String = ""
    var hasSolved = false

    var isSolving: Bool { solver.isSolving }
    var progressCount: Int { solver.progressCount }
    var solutions: [Solution]? { solver.solutions }

    var target: Int? { Int(targetText) }

    var canCalculate: Bool {
        guard let target, target > 0 else { return false }
        return !isSolving
    }

    func rollDice() {
        diceFaces = DiceRoller.roll()
        solver.cancel()
        hasSolved = false
        AppLogger.solve.debug("Rolled dice: \(self.diceFaces)")
    }

    func calculate() {
        guard let target else { return }
        hasSolved = false
        AppLogger.solve.debug("Calculating for dice \(self.diceFaces), target \(target)")
        solver.solve(dice: diceFaces, target: target) { [weak self] results in
            self?.hasSolved = true
            AppLogger.solve.debug("Found \(results.count) solutions")
        }
    }

    func resetForNewRoll() {
        solver.cancel()
        hasSolved = false
    }
}
