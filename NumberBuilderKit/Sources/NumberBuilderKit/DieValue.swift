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
    /// as 6⁰=1, 6²=36, or (6² root 2)=6. Verification is done with exact integer arithmetic
    /// (never trusting a `Double` comparison directly) so large bases don't silently round wrong.
    public func variants(maxExponent: Int, allowExponents: Bool, allowRoots: Bool) -> [DieValue] {
        guard base != 1, allowExponents else { return [self] }

        var results: [DieValue] = []
        for exponent in 0...maxExponent {
            guard let raised = Self.integerPower(base, exponent) else { continue }
            results.append(DieValue(base: base, exponent: exponent, root: 1, value: raised))

            guard allowRoots, exponent != 0 else { continue }
            for root in 2..<max(2, maxExponent) {
                guard let rootValue = Self.integerRoot(of: raised, root: root) else { continue }
                results.append(DieValue(base: base, exponent: exponent, root: root, value: rootValue))
            }
        }
        return results
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
