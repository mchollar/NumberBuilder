import XCTest
@testable import NumberBuilderKit

/// Validates the combinatorial-explosion risk flagged in the V2 plan: dice count becoming a rule
/// variant means the search space is no longer bounded to "3 dice, maxExponent 5." Empirically:
/// 5 dice at maxExponent 5 took 134s (1.26M candidates) and at maxExponent 3 took 10s -- both too
/// slow for an interactive app -- while `recommendedMaxExponent` (2 for 5 dice) took ~1s.
final class SolverEngineBenchmarkTests: XCTestCase {
    func testRecommendedMaxExponentKeepsFiveDiceInteractive() async {
        let configuration = SolverConfiguration(dice: [1, 2, 3, 4, 5], target: 15)
        XCTAssertEqual(configuration.maxExponent, 2)

        let (elapsed, solutionCount) = await time(configuration)
        print("5-dice, recommended maxExponent=\(configuration.maxExponent): \(solutionCount) solutions in \(elapsed)")
        XCTAssertLessThan(elapsed, .seconds(5), "5-dice search with the recommended cap took too long: \(elapsed)")
    }

    func testRecommendedMaxExponentDoesNotShortchangeThreeDice() async {
        // The classic 3-dice game keeps its full maxExponent of 5, matching v1.0.4 exactly.
        let configuration = SolverConfiguration(dice: [1, 2, 3], target: 6)
        XCTAssertEqual(configuration.maxExponent, 5)
    }

    private func time(_ configuration: SolverConfiguration) async -> (Duration, Int) {
        let engine = SolverEngine()
        let clock = ContinuousClock()
        let start = clock.now
        var solutionCount = 0
        for await event in await engine.solve(configuration) {
            if case .finished(let solutions) = event {
                solutionCount = solutions.count
            }
        }
        return (clock.now - start, solutionCount)
    }
}
