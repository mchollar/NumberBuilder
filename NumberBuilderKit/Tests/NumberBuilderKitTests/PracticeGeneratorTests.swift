import XCTest
@testable import NumberBuilderKit

final class PracticeGeneratorTests: XCTestCase {
    func testBasicTierPuzzleIsSolvableWithPlainDiceOnly() {
        for _ in 0..<50 {
            let puzzle = PracticeGenerator.generate(tier: .basic)
            XCTAssertEqual(puzzle.tier, .basic)
            XCTAssertTrue(puzzle.exampleSolution.dice.allSatisfy { $0.exponent == 1 && $0.root == 1 })
            assertPuzzleIsConsistent(puzzle)
        }
    }

    func testExponentsTierPuzzleRequiresANonTrivialExponent() {
        for _ in 0..<50 {
            let puzzle = PracticeGenerator.generate(tier: .exponents)
            XCTAssertEqual(puzzle.tier, .exponents)
            XCTAssertTrue(puzzle.exampleSolution.dice.contains { $0.exponent != 1 })
            XCTAssertTrue(puzzle.exampleSolution.dice.allSatisfy { $0.root == 1 })
            assertPuzzleIsConsistent(puzzle)
        }
    }

    func testRootsAndExponentsTierPuzzleRequiresANonTrivialRoot() {
        for _ in 0..<50 {
            let puzzle = PracticeGenerator.generate(tier: .rootsAndExponents)
            XCTAssertEqual(puzzle.tier, .rootsAndExponents)
            XCTAssertTrue(puzzle.exampleSolution.dice.contains { $0.root != 1 })
            assertPuzzleIsConsistent(puzzle)
        }
    }

    func testGeneratedTargetIsAlwaysPositive() {
        for tier in SolutionTier.allCases {
            for _ in 0..<20 {
                XCTAssertGreaterThan(PracticeGenerator.generate(tier: tier).target, 0)
            }
        }
    }

    func testDiceMatchTheExampleSolutionsBases() {
        let puzzle = PracticeGenerator.generate(tier: .exponents)
        XCTAssertEqual(puzzle.dice, puzzle.exampleSolution.dice.map(\.base))
    }

    private func assertPuzzleIsConsistent(_ puzzle: PracticeGenerator.Puzzle) {
        let recomputed = evaluate(dice: puzzle.exampleSolution.dice, operations: puzzle.exampleSolution.operations)
        XCTAssertEqual(recomputed, puzzle.target)
        XCTAssertEqual(puzzle.exampleSolution.result, puzzle.target)
        XCTAssertEqual(SolutionTier.classify(dice: puzzle.exampleSolution.dice), puzzle.tier)
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
