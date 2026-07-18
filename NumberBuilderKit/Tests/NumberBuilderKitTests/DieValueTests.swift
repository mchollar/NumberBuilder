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
        // 4^1 = 4, and the exact square root of 4 is 2 -- a value distinct from the base (4),
        // so this genuinely new variant should survive dedup.
        let variants = DieValue(base: 4).variants(maxExponent: 5, allowExponents: true, allowRoots: true)
        XCTAssertTrue(variants.contains { $0.exponent == 1 && $0.root == 2 && $0.value == 2 })
    }

    func testRoundTripRootIsDedupedAgainstThePlainBase() {
        // 6^2 = 36, and the exact square root of 36 is 6 -- i.e. this "variant" round-trips
        // back to the same value as the plain, unmodified die. It shouldn't be offered as a
        // separate solving technique when the plain base already covers that value, and this
        // holds for *any* base (base^n rooted by n always equals base exactly), so without
        // dedup every die would carry one of these no-op variants per exponent tried.
        let variants = DieValue(base: 6).variants(maxExponent: 5, allowExponents: true, allowRoots: true)
        XCTAssertFalse(variants.contains { $0.exponent == 2 && $0.root == 2 })
        XCTAssertEqual(variants.filter { $0.value == 6 }.count, 1)
    }

    func testVariantsAreDedupedByValue() {
        let variants = DieValue(base: 5).variants(maxExponent: 5, allowExponents: true, allowRoots: true)
        let values = variants.map(\.value)
        XCTAssertEqual(values.count, Set(values).count, "every achievable value should appear exactly once")
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

    /// All five root values from N2K's own training table (4^1/2, 4^3/2, 4^5/2, 4^7/2, 4^9/2 =
    /// 2, 8, 32, 128, 512) should be selectable -- the standard `maxExponent` cap of 5 alone only
    /// reaches the first three; `practiceVariants` searches wider for base 4 specifically to
    /// surface the other two.
    func testPracticeVariantsSurfacesAllFiveOfBaseFoursRootValues() {
        let variants = DieValue.practiceVariants(base: 4, allowExponents: true, allowRoots: true)
        let rootValues = Set(variants.filter { $0.root != 1 }.map(\.value))
        XCTAssertEqual(rootValues, [2, 8, 32, 128, 512])
    }

    /// The wider search for base 4's roots shouldn't leak newly-reachable huge *plain* powers
    /// (4^6 through 4^9) into the offered choices -- only the root-derived values are the point.
    func testPracticeVariantsDoesNotExposePlainPowersBeyondTheStandardCap() {
        let variants = DieValue.practiceVariants(base: 4, allowExponents: true, allowRoots: true)
        XCTAssertFalse(variants.contains { $0.root == 1 && $0.exponent > 5 })
    }

    /// Per-base plain exponent ceiling meets or exceeds what N2K's own training table bothers to
    /// tabulate: much higher for 2 and 3 (whose table goes to 2^9 and 3^6) than for 5 and 6
    /// (whose table stops at square/cube). 4 keeps the same lower ceiling as 5/6 for its own
    /// plain powers -- its extra headroom is for root search only (see the root-value test above).
    func testPracticeVariantsHighestPlainExponentMatchesPerBaseCeiling() {
        let expectedCeiling: [Int: Int] = [2: 9, 3: 6, 4: 5, 5: 5, 6: 5]
        for (base, ceiling) in expectedCeiling {
            let variants = DieValue.practiceVariants(base: base, allowExponents: true, allowRoots: true)
            let highestPlainExponent = variants.filter { $0.root == 1 }.map(\.exponent).max()
            XCTAssertEqual(highestPlainExponent, ceiling, "base \(base) should offer plain exponents up to \(ceiling)")
        }
    }

    /// Base 1 is unaffected by any of this -- always just the identity value.
    func testPracticeVariantsForBaseOneIsUnaffected() {
        let practice = DieValue.practiceVariants(base: 1, allowExponents: true, allowRoots: true)
        XCTAssertEqual(practice, [DieValue(base: 1)])
    }
}
