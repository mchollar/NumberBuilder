import XCTest
@testable import NumberBuilderKit

final class ExpressionTests: XCTestCase {
    func testEvaluatesLeftToRightWithNoPrecedence() {
        // 5 + 2 x 3 read left to right is (5+2)x3 = 21, not the standard-order-of-operations 11.
        let dice = [DieValue(base: 5), DieValue(base: 2), DieValue(base: 3)]
        XCTAssertEqual(evaluate(dice: dice, operations: [.add, .multiply]), 21)
    }

    func testSingleDieNeedsNoOperations() {
        XCTAssertEqual(evaluate(dice: [DieValue(base: 7)], operations: []), 7)
    }

    func testReturnsNilForMismatchedOperationCount() {
        let dice = [DieValue(base: 1), DieValue(base: 2), DieValue(base: 3)]
        XCTAssertNil(evaluate(dice: dice, operations: [.add]))
    }

    func testReturnsNilForEmptyDice() {
        XCTAssertNil(evaluate(dice: [], operations: []))
    }

    func testReturnsNilForInexactDivision() {
        let dice = [DieValue(base: 5), DieValue(base: 2)]
        XCTAssertNil(evaluate(dice: dice, operations: [.divide]))
    }
}

final class SolutionTierClassifyTests: XCTestCase {
    func testPlainDiceAreBasic() {
        let dice = [DieValue(base: 5), DieValue(base: 3)]
        XCTAssertEqual(SolutionTier.classify(dice: dice), .basic)
    }

    func testAnyExponentMakesItExponentsTier() {
        let exponentDie = DieValue(base: 4)
            .variants(maxExponent: 3, allowExponents: true, allowRoots: false)
            .first { $0.exponent != 1 } ?? DieValue(base: 4)
        let dice = [exponentDie, DieValue(base: 3)]
        XCTAssertEqual(SolutionTier.classify(dice: dice), .exponents)
    }

    func testAnyRootMakesItRootsAndExponentsTierEvenAlongsideAnExponent() {
        let rootDie = DieValue(base: 4)
            .variants(maxExponent: 3, allowExponents: true, allowRoots: true)
            .first { $0.root != 1 } ?? DieValue(base: 4)
        let exponentDie = DieValue(base: 5)
            .variants(maxExponent: 3, allowExponents: true, allowRoots: false)
            .first { $0.exponent != 1 } ?? DieValue(base: 5)
        XCTAssertEqual(SolutionTier.classify(dice: [rootDie, exponentDie]), .rootsAndExponents)
    }
}
