import XCTest
@testable import NumberBuilderKit

/// Validates the combinatorial-explosion risk flagged in the V2 plan: dice count becoming a rule
/// variant means the search space is no longer bounded to "3 dice, maxExponent 5." Original
/// brute-force numbers (no target-directed pruning): 5 dice at maxExponent 5 took 134s (1.26M
/// candidates), maxExponent 3 took 10s -- both too slow for an interactive app -- while the
/// original `recommendedMaxExponent` (2 for 5 dice) took ~1s.
///
/// After adding branch-and-bound pruning to `SolverEngine.Search` (an interval bound on what's
/// still reachable from the remaining dice, checked before recursing further -- see
/// `isTargetStillReachable`/`reachableRange`), the same configs measure: maxExponent 5 -> ~14s
/// (~9.5x faster), maxExponent 3 -> ~4s (~2.5x faster). maxExponent 2 is a hair slower (~1.1s vs
/// ~0.8s) since pruning has little to cut there and the bound computation itself has a small
/// fixed cost per node. Pruning correctness is cross-validated against a brute-force reference
/// across many randomized configs in `PruningValidationTest`. Given the ~4s number at maxExponent
/// 3, `recommendedMaxExponent(forDiceCount:)` was raised from 2 to 3 for 5 dice.
final class SolverEngineBenchmarkTests: XCTestCase {
    func testRecommendedMaxExponentKeepsFiveDiceInteractive() async {
        let configuration = SolverConfiguration(dice: [1, 2, 3, 4, 5], target: 15)
        XCTAssertEqual(configuration.maxExponent, 3)

        let (elapsed, solutionCount) = await time(configuration)
        print("5-dice, recommended maxExponent=\(configuration.maxExponent): \(solutionCount) solutions in \(elapsed)")
        XCTAssertLessThan(elapsed, .seconds(10), "5-dice search with the recommended cap took too long: \(elapsed)")
    }

    func testPrunedSearchAtMaxExponentFiveStaysUnderPreviousBruteForceTime() async {
        // Not asserting a specific tight bound (timing tests are inherently a little flaky across
        // machines/load) -- just confirming pruning keeps even the worst-case config well clear of
        // the old 134s brute-force time, as a regression guard against the pruning silently
        // regressing to a no-op.
        let configuration = SolverConfiguration(dice: [1, 2, 3, 4, 5], target: 15, maxExponent: 5)
        let (elapsed, solutionCount) = await time(configuration)
        print("PRUNED 5-dice maxExponent=5: \(solutionCount) solutions in \(elapsed)")
        XCTAssertLessThan(elapsed, .seconds(60), "Pruned search regressed toward the old brute-force time: \(elapsed)")
    }

    func testRecommendedMaxExponentDoesNotShortchangeThreeDice() async {
        // 9, not 5 -- raised so this ceiling never clips `DieValue.challengeVariants`' own
        // per-base table (base 2 needs up to 9, base 4's root search needs up to 9 to reach
        // 4^(7/2)=128 and 4^(9/2)=512). The classic 3-dice game should see everything Challenge
        // mode can generate, not a narrower flat cap.
        let configuration = SolverConfiguration(dice: [1, 2, 3], target: 6)
        XCTAssertEqual(configuration.maxExponent, 9)
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
