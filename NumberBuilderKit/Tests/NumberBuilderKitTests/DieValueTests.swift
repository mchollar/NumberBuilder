import XCTest
@testable import NumberBuilderKit

final class DieValueTests: XCTestCase {
    func testIdentityVariantForBaseOne() {
        let variants = DieValue(base: 1).variants(maxExponent: 5, allowExponents: true, allowRoots: true)
        XCTAssertEqual(variants, [DieValue(base: 1)])
    }

    func testExponentVariantsIncludeZeroPower() {
        let variants = DieValue(base: 6).variants(maxExponent: 5, allowExponents: true, allowRoots: false)
        XCTAssertTrue(variants.contains { $0.exponent == 0 && $0.value == 1 })
        XCTAssertTrue(variants.contains { $0.exponent == 2 && $0.value == 36 })
    }

    func testRootVariantOnlyAppearsWhenExact() {
        let variants = DieValue(base: 6).variants(maxExponent: 5, allowExponents: true, allowRoots: true)
        // 6^2 = 36, and the exact square root of 36 is 6.
        XCTAssertTrue(variants.contains { $0.exponent == 2 && $0.root == 2 && $0.value == 6 })
    }

    func testDisallowingExponentsReturnsOnlyIdentity() {
        let variants = DieValue(base: 6).variants(maxExponent: 5, allowExponents: false, allowRoots: true)
        XCTAssertEqual(variants, [DieValue(base: 6)])
    }

    func testSmallMaxExponentDoesNotCrashRootRange() {
        // maxExponent < 2 used to make the original app's `2..<maxPower` range trap at runtime.
        XCTAssertNoThrow(DieValue(base: 6).variants(maxExponent: 1, allowExponents: true, allowRoots: true))
    }

    func testIntegerRootDoesNotFalsePositiveForNonPerfectRoots() {
        // 999983 is prime, so it has no exact integer square or cube root.
        XCTAssertNil(DieValue.integerRoot(of: 999_983, root: 2))
        XCTAssertNil(DieValue.integerRoot(of: 999_983, root: 3))
    }

    func testIntegerRootFindsExactLargeRoot() {
        // 46656 = 6^6 = 216^2 = 36^3 -- exercise a root large enough that a naive
        // `Double` comparison is exactly the kind of case that can round wrong.
        XCTAssertEqual(DieValue.integerRoot(of: 46_656, root: 2), 216)
        XCTAssertEqual(DieValue.integerRoot(of: 46_656, root: 3), 36)
    }

    func testIntegerPowerOverflowReturnsNilInsteadOfWrapping() {
        XCTAssertNil(DieValue.integerPower(Int.max, 2))
    }
}
