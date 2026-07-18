import Foundation

/// A number derived from a single rolled die, optionally raised to a power and/or root
/// (e.g. the die shows 6, but this represents 6² = 36, or 6² root 2 = 6).
public struct DieValue: Hashable, Sendable, Comparable {
    public let base: Int
    public let exponent: Int
    public let root: Int
    public let value: Int

    public init(base: Int) {
        self.init(base: base, exponent: 1, root: 1, value: base)
    }

    private init(base: Int, exponent: Int, root: Int, value: Int) {
        self.base = base
        self.exponent = exponent
        self.root = root
        self.value = value
    }

    public static func < (lhs: DieValue, rhs: DieValue) -> Bool {
        lhs.value < rhs.value
    }

    /// Every power/root variant of this die's rolled value, e.g. a rolled 6 can also stand in
    /// as 6⁰=1 or 6²=36. Verification is done with exact integer arithmetic (never trusting a
    /// `Double` comparison directly) so large bases don't silently round wrong.
    ///
    /// Deduplicated by the resulting `value`, keeping the simplest exponent/root that reaches
    /// it (iteration order is exponent ascending, root=1 before root>1, so "simplest" falls out
    /// for free). This is deliberate: for *any* base, `base^n` rooted by `n` always round-trips
    /// back to `base` exactly (6² root 2 = 6, 6³ root 3 = 6, 6⁴ root 4 = 6, ...), so without
    /// dedup every die contributes a pile of same-valued variants that only look like distinct
    /// solving techniques. Each achievable value is still represented exactly once.
    public func variants(maxExponent: Int, allowExponents: Bool, allowRoots: Bool) -> [DieValue] {
        guard base != 1, allowExponents else { return [self] }

        var results: [DieValue] = []
        var seenValues: Set<Int> = []

        func append(_ candidate: DieValue) {
            guard seenValues.insert(candidate.value).inserted else { return }
            results.append(candidate)
        }

        for exponent in 0...maxExponent {
            guard let raised = Self.integerPower(base, exponent) else { continue }
            append(DieValue(base: base, exponent: exponent, root: 1, value: raised))

            guard allowRoots, exponent != 0 else { continue }
            for root in 2..<max(2, maxExponent) {
                guard let rootValue = Self.integerRoot(of: raised, root: root) else { continue }
                append(DieValue(base: base, exponent: exponent, root: root, value: rootValue))
            }
        }
        return results
    }

    /// Plain exponent ceiling per base -- meets or exceeds which powers N2K's own training
    /// materials bother to tabulate: much higher for the small bases their table also goes far
    /// with (2, 3) than for the bases it stops at square/cube (5, 6). 4 keeps the same ceiling as
    /// 5/6 for its own *plain* powers -- its extra headroom in `practiceVariants` below exists
    /// only for root search, not for plain exponent choices.
    private static func maxPlainExponent(forBase base: Int) -> Int {
        switch base {
        case 2: return 9
        case 3: return 6
        default: return 5
        }
    }

    /// Every variant Challenge should ever offer for a rolled `base`, whether generating a puzzle
    /// or letting the player manually choose. Wraps `variants(maxExponent:allowExponents:allowRoots:)`
    /// with Practice-specific tuning: 4 is the only face (1-6) that can ever produce a genuine
    /// root value at all -- for any other base, an exact root always round-trips back to a lower
    /// plain power of the same base, which `variants` already dedups away as a duplicate. At 4's
    /// own plain cap of 5, only three of those surface (4^(1/2)=2, 4^(3/2)=8, 4^(5/2)=32); two
    /// more real ones from N2K's own training table, 4^(7/2)=128 and 4^(9/2)=512, need a wider
    /// exponent search. Search wider for base 4 specifically when roots are allowed, then drop
    /// any resulting *plain* power beyond its own ceiling -- the goal is exposing those two extra
    /// root values, not a pile of newly-reachable huge plain exponent choices like 4^7=16384
    /// itself.
    public static func practiceVariants(base: Int, allowExponents: Bool, allowRoots: Bool) -> [DieValue] {
        let plainCap = maxPlainExponent(forBase: base)
        let searchCap = (base == 4 && allowRoots) ? 9 : plainCap
        let variants = DieValue(base: base).variants(maxExponent: searchCap, allowExponents: allowExponents, allowRoots: allowRoots)
        return variants.filter { $0.root != 1 || $0.exponent <= plainCap }
    }

    /// Exact integer exponentiation with overflow protection; `nil` on overflow.
    static func integerPower(_ base: Int, _ exponent: Int) -> Int? {
        guard exponent >= 0 else { return nil }
        var result = 1
        for _ in 0..<exponent {
            let (partial, overflow) = result.multipliedReportingOverflow(by: base)
            if overflow { return nil }
            result = partial
        }
        return result
    }

    /// The exact integer `root`-th root of `n`, or `nil` if none exists. Uses `Double` only to
    /// pick a small candidate window, then confirms exactness with integer multiplication —
    /// this is what fixes a real bug in the original app, where a raw `Double` comparison could
    /// misjudge "is this a perfect root" for larger bases due to floating-point rounding.
    static func integerRoot(of n: Int, root: Int) -> Int? {
        guard n >= 0, root > 0 else { return nil }
        if n == 0 { return 0 }
        if n == 1 { return 1 }
        let estimate = Int(pow(Double(n), 1.0 / Double(root)).rounded())
        for candidate in max(0, estimate - 2)...(estimate + 2) {
            if let power = integerPower(candidate, root), power == n {
                return candidate
            }
        }
        return nil
    }
}
