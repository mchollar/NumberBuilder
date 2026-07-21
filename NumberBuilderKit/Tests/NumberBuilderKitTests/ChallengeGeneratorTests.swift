import XCTest
@testable import NumberBuilderKit

final class ChallengeGeneratorTests: XCTestCase {
    func testLevelOnePuzzleIsSolvableWithPlainDiceOnly() {
        for _ in 0..<50 {
            let puzzle = ChallengeGenerator.generate(level: .one)
            XCTAssertEqual(puzzle.tier, .basic)
            XCTAssertTrue(puzzle.exampleSolution.dice.allSatisfy { $0.exponent == 1 && $0.root == 1 })
            assertPuzzleIsConsistent(puzzle)
        }
    }

    func testExponentsLevelPuzzleRequiresANonTrivialExponent() {
        for level in [ChallengeLevel.three, .four] {
            for _ in 0..<50 {
                let puzzle = ChallengeGenerator.generate(level: level)
                XCTAssertEqual(puzzle.tier, .exponents)
                XCTAssertTrue(puzzle.exampleSolution.dice.contains { $0.exponent != 1 })
                XCTAssertTrue(puzzle.exampleSolution.dice.allSatisfy { $0.root == 1 })
                assertPuzzleIsConsistent(puzzle)
            }
        }
    }

    /// Roots levels used to *force* a root onto every single puzzle -- but since only a rolled 4
    /// can ever produce a root value, that silently meant "every Roots-level roll must contain a
    /// 4," turning a technique meant to be a possibility into a hidden requirement on the dice.
    /// Fixed to force "some non-trivial technique" instead of "a root specifically": every puzzle
    /// still demonstrably steps up from Basic, but a fractional exponent is now something that
    /// *can* appear, not something every roll is engineered around. Both halves matter here --
    /// roots must still be reachable, and must not be mandatory every time.
    func testRootsLevelPuzzleMayIncludeButDoesNotRequireANonTrivialRoot() {
        for level in [ChallengeLevel.five, .six] {
            var sawRoot = false
            var sawNoRoot = false
            for _ in 0..<200 {
                let puzzle = ChallengeGenerator.generate(level: level)
                XCTAssertEqual(puzzle.tier, .rootsAndExponents, "the level's ceiling stays rootsAndExponents regardless of what a specific puzzle uses")
                XCTAssertTrue(puzzle.exampleSolution.dice.contains { $0.exponent != 1 || $0.root != 1 }, "every puzzle should still demonstrate some non-trivial technique")
                if puzzle.exampleSolution.dice.contains(where: { $0.root != 1 }) {
                    sawRoot = true
                } else {
                    sawNoRoot = true
                }
                assertPuzzleIsConsistent(puzzle)
            }
            XCTAssertTrue(sawRoot, "a root should still be reachable at level \(level) across enough tries")
            XCTAssertTrue(sawNoRoot, "a root should not be forced onto every single puzzle at level \(level)")
        }
    }

    func testGeneratedTargetIsAlwaysPositive() {
        for level in ChallengeLevel.allCases {
            for _ in 0..<20 {
                XCTAssertGreaterThan(ChallengeGenerator.generate(level: level).target, 0)
            }
        }
    }

    /// The actual bug this whole level system replaced a design over: a target could previously
    /// exceed 100 even on the second-easiest setting, because capping one die's exponent doesn't
    /// bound what the dice combine to. Every level must now honor its own ceiling exactly.
    func testGeneratedTargetNeverExceedsTheLevelsMaxTarget() {
        for level in ChallengeLevel.allCases {
            for _ in 0..<50 {
                let puzzle = ChallengeGenerator.generate(level: level)
                XCTAssertLessThanOrEqual(puzzle.target, level.maxTarget, "level \(level) produced a target over its own ceiling")
            }
        }
    }

    func testDiceMatchTheExampleSolutionsBases() {
        let puzzle = ChallengeGenerator.generate(level: .three)
        XCTAssertEqual(puzzle.dice, puzzle.exampleSolution.dice.map(\.base))
    }

    /// Permanent regression guard, not a one-off -- an earlier design (per-die exponent caps
    /// instead of a target ceiling) made one tier/setting combination mathematically unreachable,
    /// which turned `ChallengeGenerator.generate`'s retry loop into a real infinite loop that
    /// pinned the CPU and froze the app. This test would have caught it: it exercises every level
    /// directly and fails loudly if any of them can't be generated quickly and without falling
    /// back to a different level.
    func testEveryLevelTerminates() {
        for level in ChallengeLevel.allCases {
            let start = Date()
            let puzzle = ChallengeGenerator.generate(level: level)
            let elapsed = Date().timeIntervalSince(start)
            XCTAssertEqual(puzzle.level, level, "level \(level) fell back instead of generating directly")
            XCTAssertLessThan(elapsed, 2.0, "level \(level) took \(elapsed)s -- possible near-exhausted retry loop")
            assertPuzzleIsConsistent(puzzle)
        }
    }

    private func assertPuzzleIsConsistent(_ puzzle: ChallengeGenerator.Puzzle) {
        let recomputed = evaluate(dice: puzzle.exampleSolution.dice, operations: puzzle.exampleSolution.operations)
        XCTAssertEqual(recomputed, puzzle.target)
        XCTAssertEqual(puzzle.exampleSolution.result, puzzle.target)
        // Solution.tier reflects what these specific dice actually use, which can now be *below*
        // the puzzle's own level ceiling (puzzle.tier) -- never above it, since a level's own
        // allowExponents/allowRoots already prevents ever exceeding what it permits.
        XCTAssertEqual(SolutionTier.classify(dice: puzzle.exampleSolution.dice), puzzle.exampleSolution.tier)
        XCTAssertLessThanOrEqual(puzzle.exampleSolution.tier, puzzle.tier)
    }
}

final class DiceRollerTests: XCTestCase {
    func testNeverRollsMoreThanOneOne() {
        for _ in 0..<200 {
            let faces = DiceRoller.roll()
            XCTAssertLessThanOrEqual(faces.filter { $0 == 1 }.count, 1)
        }
    }

    func testRespectsCountAndSides() {
        let faces = DiceRoller.roll(count: 5, sides: 8)
        XCTAssertEqual(faces.count, 5)
        XCTAssertTrue(faces.allSatisfy { (1...8).contains($0) })
    }
}
