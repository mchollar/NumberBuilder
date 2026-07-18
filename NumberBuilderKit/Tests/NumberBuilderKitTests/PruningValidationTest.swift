import XCTest
@testable import NumberBuilderKit

/// Cross-validates the pruned `SolverEngine` search against a synchronous reference
/// implementation of the pre-pruning brute-force algorithm (copied verbatim from commit
/// `8f4d691`, the last commit before pruning), across many randomized configurations.
///
/// This exists because the first pruning attempt (folding remaining dice into a bound in one
/// fixed order) *looked* reasonable but was actually unsafe -- it silently dropped valid
/// solutions in ~3% of randomized configs (11/320 on the first run here). The fix was to make
/// the bound branch over *which die comes next*, mirroring the real search's structure exactly
/// rather than assuming a fixed processing order. Keeping this as a permanent regression test
/// (not a one-off) guards against a future change to the pruning bound reintroducing that class
/// of bug, which would otherwise be silent -- the app would just quietly show fewer solutions
/// than it should.
final class PruningValidationTest: XCTestCase {
    func testPrunedSearchMatchesBruteForceAcrossManyConfigs() async throws {
        var rng = SplitMix64(seed: 0xC0FFEE)
        var mismatches: [String] = []
        var configsChecked = 0

        // Main sweep: 1-4 dice, full exponent range -- brute force stays fast here (the
        // existing benchmark test already establishes 4 dice is sub-second even at maxExponent 5).
        for _ in 0..<200 {
            configsChecked += try await checkOneConfig(
                diceCount: Int.random(in: 1...4, using: &rng),
                maxExponentRange: 0...5,
                rng: &rng,
                mismatches: &mismatches
            )
        }

        // 5-dice sweep: kept small and to maxExponent 0...3 so the *reference* brute force
        // (which has no pruning at all) stays tractable and this test stays fast enough to run
        // routinely -- maxExponent 5 alone is the ~134s brute-force case.
        for _ in 0..<10 {
            configsChecked += try await checkOneConfig(
                diceCount: 5,
                maxExponentRange: 0...3,
                rng: &rng,
                mismatches: &mismatches
            )
        }

        print("Checked \(configsChecked) random configs, \(mismatches.count) mismatches")
        if !mismatches.isEmpty {
            XCTFail("Pruned search diverged from brute force in \(mismatches.count) configs:\n" + mismatches.prefix(10).joined(separator: "\n"))
        }
    }

    private func checkOneConfig(
        diceCount: Int,
        maxExponentRange: ClosedRange<Int>,
        rng: inout SplitMix64,
        mismatches: inout [String]
    ) async throws -> Int {
        let sides = [6, 8, 10, 12].randomElement(using: &rng)!
        let dice = (0..<diceCount).map { _ in Int.random(in: 1...sides, using: &rng) }
        let target = Int.random(in: 1...(sides * sides), using: &rng)
        let allowExponents = Bool.random(using: &rng)
        let allowRoots = allowExponents && Bool.random(using: &rng)
        let maxExponent = Int.random(in: maxExponentRange, using: &rng)

        let config = SolverConfiguration(
            dice: dice,
            target: target,
            allowExponents: allowExponents,
            allowRoots: allowRoots,
            maxExponent: maxExponent
        )

        let bruteForce = Set(BruteForceReference.solve(config))
        let pruned = Set(await solve(config))

        if bruteForce != pruned {
            mismatches.append(
                "dice=\(dice) target=\(target) exp=\(allowExponents) roots=\(allowRoots) maxExp=\(maxExponent): "
                    + "brute=\(bruteForce.count) pruned=\(pruned.count) "
                    + "missing=\(bruteForce.subtracting(pruned).count) extra=\(pruned.subtracting(bruteForce).count)"
            )
        }
        return 1
    }

    private func solve(_ configuration: SolverConfiguration) async -> [Solution] {
        let engine = SolverEngine()
        var finalSolutions: [Solution] = []
        for await event in await engine.solve(configuration) {
            if case .finished(let solutions) = event { finalSolutions = solutions }
        }
        return finalSolutions
    }
}

/// A tiny deterministic RNG so the randomized config sweep is reproducible.
private struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Verbatim copy of the pre-pruning search (from commit 8f4d691, before this change), used
/// only as a reference oracle for cross-validation. No `isTargetStillReachable` pruning.
private enum BruteForceReference {
    static func solve(_ configuration: SolverConfiguration) -> [Solution] {
        guard !configuration.dice.isEmpty, configuration.target > 0 else { return [] }

        // Must match SolverEngine.run's own variant computation exactly -- otherwise this
        // "reference" would be comparing the pruned search against a differently-shaped search
        // space instead of validating the pruning itself, and could report spurious mismatches
        // (or worse, mask a real one).
        let variantSets: [[DieValue]] = configuration.dice.map { face in
            DieValue.practiceVariants(
                base: face,
                allowExponents: configuration.allowExponents,
                allowRoots: configuration.allowRoots
            ).filter { $0.exponent <= configuration.maxExponent }
        }

        var search = Search(target: configuration.target, variantSets: variantSets, used: Array(repeating: false, count: configuration.dice.count))
        search.run()
        return search.solutions
    }

    private struct Search {
        let target: Int
        let variantSets: [[DieValue]]
        var used: [Bool]
        var chosenDice: [DieValue] = []
        var chosenOperations: [MathOperation] = []
        var solutions: [Solution] = []
        private var seenSolutions: Set<Solution> = []

        init(target: Int, variantSets: [[DieValue]], used: [Bool]) {
            self.target = target
            self.variantSets = variantSets
            self.used = used
        }

        mutating func run() {
            step(accumulator: nil)
        }

        private mutating func step(accumulator: Int?) {
            if chosenDice.count == variantSets.count {
                if let result = accumulator, result == target {
                    let solution = Solution(result: result, dice: chosenDice, operations: chosenOperations, tier: Self.tier(for: chosenDice))
                    if seenSolutions.insert(solution).inserted {
                        solutions.append(solution)
                    }
                }
                return
            }

            for dieIndex in variantSets.indices where !used[dieIndex] {
                used[dieIndex] = true
                for variant in variantSets[dieIndex] {
                    chosenDice.append(variant)

                    if let accumulator {
                        for operation in MathOperation.allCases {
                            if operation == .divide && variant.value == 1 { continue }
                            if let next = operation.apply(accumulator, variant.value) {
                                chosenOperations.append(operation)
                                step(accumulator: next)
                                chosenOperations.removeLast()
                            }
                        }
                    } else {
                        step(accumulator: variant.value)
                    }

                    chosenDice.removeLast()
                }
                used[dieIndex] = false
            }
        }

        private static func tier(for dice: [DieValue]) -> SolutionTier {
            var usesExponent = false
            for die in dice {
                if die.root != 1 { return .rootsAndExponents }
                if die.exponent != 1 { usesExponent = true }
            }
            return usesExponent ? .exponents : .basic
        }
    }
}
