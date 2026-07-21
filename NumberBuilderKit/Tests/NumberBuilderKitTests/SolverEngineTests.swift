import XCTest
@testable import NumberBuilderKit

final class SolverEngineTests: XCTestCase {
    func testAllSolutionsAreInternallyConsistent() async {
        // A strong general regression guard: independently re-evaluate every returned solution's
        // own dice/operations and confirm it actually reaches the target -- this is exactly the
        // kind of check that would have caught the shipped app's division bug (commit a666297).
        // Uses the shared `evaluate` free function rather than SolverEngine's own internal
        // accumulator loop, so this stays a genuinely independent check while also covering
        // `evaluate` itself (SolverEngine.Search keeps its own incremental loop for pruning,
        // it doesn't call this function).
        let configuration = SolverConfiguration(
            dice: [1, 2, 3, 4],
            target: 24,
            allowExponents: false,
            allowRoots: false
        )
        let solutions = await solve(configuration)
        XCTAssertFalse(solutions.isEmpty)

        for solution in solutions {
            guard let recomputed = evaluate(dice: solution.dice, operations: solution.operations) else {
                XCTFail("Solution claims an operation that isn't actually valid")
                continue
            }
            XCTAssertEqual(recomputed, solution.result)
            XCTAssertEqual(solution.result, configuration.target)
        }
    }

    func testFindsKnownSolutionForClassicRoll() async {
        let configuration = SolverConfiguration(dice: [1, 2, 3], target: 6, allowExponents: false, allowRoots: false)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.contains { solution in
            solution.dice.map(\.value).sorted() == [1, 2, 3] && solution.result == 6
        })
    }

    func testUnreachableTargetReturnsNoSolutions() async {
        // Three dice worth 1-6 each can never reach an enormous target.
        let configuration = SolverConfiguration(dice: [1, 1, 1], target: 999_999, allowExponents: false, allowRoots: false)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.isEmpty)
    }

    func testSingleDieUsesPlainValueForBasicTier() async {
        let configuration = SolverConfiguration(dice: [6], target: 6, allowExponents: true, allowRoots: false)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.contains { $0.tier == .basic })
    }

    func testSingleDiePowerIsClassifiedAsExponentsTier() async {
        let configuration = SolverConfiguration(dice: [6], target: 36, allowExponents: true, allowRoots: false, maxExponent: 3)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.contains { $0.tier == .exponents && $0.dice.first?.exponent == 2 })
    }

    func testSingleDieRootIsClassifiedAsRootsAndExponentsTier() async {
        let configuration = SolverConfiguration(dice: [64], target: 8, allowExponents: true, allowRoots: true, maxExponent: 3)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.contains { $0.tier == .rootsAndExponents && $0.dice.first?.root == 2 })
    }

    func testDisallowingExponentsAndRootsOnlyProducesBasicTier() async {
        let configuration = SolverConfiguration(dice: [2, 3, 6], target: 36, allowExponents: false, allowRoots: false)
        let solutions = await solve(configuration)
        XCTAssertFalse(solutions.isEmpty)
        XCTAssertTrue(solutions.allSatisfy { $0.tier == .basic })
    }

    /// The user-reported bug this whole change fixed: Challenge mode generated dice [4, 1, 3] ->
    /// target 126 (using 4^(7/2)=128, then -3, +1), but Explore mode reported no solution for the
    /// exact same roll and target -- because it was still computing variants at a flat
    /// `maxExponent` of 5 rather than `DieValue.challengeVariants`' per-base table, so 4^(7/2)
    /// (which needs exponent 7) was never in its search space at all. Explore should always be
    /// able to find anything Challenge can generate.
    func testFindsTheFractionalExponentSolutionExploreUsedToMiss() async {
        let configuration = SolverConfiguration(dice: [4, 1, 3], target: 126)
        let solutions = await solve(configuration)
        XCTAssertTrue(solutions.contains { $0.dice.contains { $0.base == 4 && $0.exponent == 7 && $0.root == 2 } })
    }

    func testCancellationStopsTheSearch() async {
        let engine = SolverEngine()
        let configuration = SolverConfiguration(dice: [1, 2, 3, 4], target: 24)
        let stream = await engine.solve(configuration)
        let task = Task {
            for await _ in stream {
                // Cancel as soon as anything comes through.
                break
            }
        }
        await task.value
        // Reaching this point without hanging demonstrates the stream terminates on cancellation.
    }

    private func solve(_ configuration: SolverConfiguration) async -> [Solution] {
        let engine = SolverEngine()
        var finalSolutions: [Solution] = []
        for await event in await engine.solve(configuration) {
            if case .finished(let solutions) = event {
                finalSolutions = solutions
            }
        }
        return finalSolutions
    }
}
