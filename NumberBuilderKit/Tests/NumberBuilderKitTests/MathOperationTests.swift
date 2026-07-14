import XCTest
@testable import NumberBuilderKit

final class MathOperationTests: XCTestCase {
    func testAddSubtractMultiply() {
        XCTAssertEqual(MathOperation.add.apply(2, 3), 5)
        XCTAssertEqual(MathOperation.subtract.apply(5, 3), 2)
        XCTAssertEqual(MathOperation.multiply.apply(4, 3), 12)
    }

    func testDivideAcceptsExactDivision() {
        XCTAssertEqual(MathOperation.divide.apply(6, 2), 3)
    }

    func testDivideRejectsInexactDivision() {
        // Regression guard for the shipped app's division bug (commit a666297).
        XCTAssertNil(MathOperation.divide.apply(7, 2))
    }

    func testDivideRejectsDivisionByZero() {
        XCTAssertNil(MathOperation.divide.apply(5, 0))
    }
}
