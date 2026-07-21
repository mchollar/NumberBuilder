/// A progress update or final result from a `SolverEngine.solve(_:)` search.
public enum SolveEvent: Sendable {
    case progress(count: Int)
    case finished([Solution])
}

/// Searches every way of combining a roll's dice — including power/root variants when the rule
/// variant allows them — to reach a target number, streaming results as they're found rather
/// than materializing every candidate before filtering.
public actor SolverEngine {
    public init() {}

    public func solve(_ configuration: SolverConfiguration) -> AsyncStream<SolveEvent> {
        AsyncStream { continuation in
            let task = Task {
                await self.run(configuration, into: continuation)
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(
        _ configuration: SolverConfiguration,
        into continuation: AsyncStream<SolveEvent>.Continuation
    ) async {
        guard !configuration.dice.isEmpty, configuration.target > 0 else {
            continuation.yield(.finished([]))
            continuation.finish()
            return
        }

        // `challengeVariants` matches Challenge mode's own per-base exponent table exactly
        // (higher for small bases like 2/3, base 4's extra root search for 128/512) rather than
        // one flat number applied to every base -- without it, Explore could report "no solution"
        // for a target Challenge had just generated moments earlier (e.g. 4^(7/2)=128 needing
        // exponent 7, out of reach of the old flat cap of 5). Still intersected with
        // `configuration.maxExponent` so the 5-dice/6+-dice performance ceilings below remain in
        // effect -- challengeVariants' own table only ever gets to apply in full when the ceiling
        // is high enough to not clip it, which `recommendedMaxExponent` guarantees for the
        // classic under-5-dice case.
        let variantSets: [[DieValue]] = configuration.dice.map { face in
            DieValue.challengeVariants(
                base: face,
                allowExponents: configuration.allowExponents,
                allowRoots: configuration.allowRoots
            ).filter { $0.exponent <= configuration.maxExponent }
        }

        var search = Search(
            target: configuration.target,
            variantSets: variantSets,
            used: Array(repeating: false, count: configuration.dice.count)
        )
        await search.run(continuation: continuation)

        if Task.isCancelled {
            continuation.finish()
            return
        }

        search.solutions.sort()
        continuation.yield(.finished(search.solutions))
        continuation.finish()
    }

    /// Depth-first search over "which die next, which of its power/root variants, which
    /// operation joins it to the running expression" — evaluated strictly left to right, exactly
    /// as the physical game is played, so no operator-precedence ambiguity ever arises. Carrying
    /// the running accumulator through the recursion (rather than only checking the final result)
    /// means an inexact division kills that branch immediately instead of exploring every
    /// remaining die underneath a value that could never have worked anyway.
    private struct Search {
        let target: Int
        let variantSets: [[DieValue]]
        var used: [Bool]
        var chosenDice: [DieValue] = []
        var chosenOperations: [MathOperation] = []
        var solutions: [Solution] = []
        private var seenSolutions: Set<Solution> = []
        private var foundSinceLastYield = 0

        init(target: Int, variantSets: [[DieValue]], used: [Bool]) {
            self.target = target
            self.variantSets = variantSets
            self.used = used
        }

        mutating func run(continuation: AsyncStream<SolveEvent>.Continuation) async {
            await step(accumulator: nil, continuation: continuation)
        }

        private mutating func step(
            accumulator: Int?,
            continuation: AsyncStream<SolveEvent>.Continuation
        ) async {
            if Task.isCancelled { return }

            if chosenDice.count == variantSets.count {
                if let result = accumulator, result == target {
                    let solution = Solution(
                        result: result,
                        dice: chosenDice,
                        operations: chosenOperations,
                        tier: SolutionTier.classify(dice: chosenDice)
                    )
                    // Two dice showing the same face (e.g. a roll of 5, 5, 6) are interchangeable,
                    // so trying "die A's 5 then die B's 5" and "die B's 5 then die A's 5" produces
                    // byte-for-byte identical solutions. Dedup here rather than post-hoc so the
                    // live progress count and the final list agree.
                    if seenSolutions.insert(solution).inserted {
                        solutions.append(solution)
                        foundSinceLastYield += 1
                        if foundSinceLastYield >= 25 {
                            continuation.yield(.progress(count: solutions.count))
                            foundSinceLastYield = 0
                            await Task.yield()
                        }
                    }
                }
                return
            }

            for dieIndex in variantSets.indices where !used[dieIndex] {
                used[dieIndex] = true
                let remainingIndices = variantSets.indices.filter { !used[$0] }

                for variant in variantSets[dieIndex] {
                    chosenDice.append(variant)

                    if let accumulator {
                        for operation in MathOperation.allCases {
                            // A die worth 1 (typically from `^0`) makes `× 1` and `÷ 1` produce the
                            // same next accumulator and the same solution space beneath it, so only
                            // one needs exploring; skipping `÷` here is the source-level fix for
                            // solutions that only differ by that redundant operation choice.
                            if operation == .divide && variant.value == 1 { continue }
                            if let next = operation.apply(accumulator, variant.value),
                               isTargetStillReachable(from: next, remainingIndices: remainingIndices) {
                                chosenOperations.append(operation)
                                await step(accumulator: next, continuation: continuation)
                                chosenOperations.removeLast()
                            }
                        }
                    } else if isTargetStillReachable(from: variant.value, remainingIndices: remainingIndices) {
                        await step(accumulator: variant.value, continuation: continuation)
                    }

                    chosenDice.removeLast()
                }
                used[dieIndex] = false
            }
        }

        /// A deliberately loose but *safe* bound on the search space: computes an interval
        /// guaranteed to contain every value reachable from `accumulator` using the remaining
        /// dice, in *any* order, via *any* operator sequence. This mirrors the real search's own
        /// "try each remaining die next" branching exactly (rather than folding dice in one fixed
        /// order, which turned out to understate the reachable range for some orderings and
        /// unsafely prune valid solutions -- caught by cross-validating against a brute-force
        /// reference in `PruningValidationTest` before this shape was settled on). Each die
        /// contributes its full [min, max] variant range rather than a single value, and real
        /// (non-integer) division is used rather than exact-only, both of which only ever widen
        /// the bound -- so this can never wrongly exclude a target that's actually reachable, only
        /// skip branches that have already gone somewhere no operator sequence could recover from.
        private func isTargetStillReachable(from accumulator: Int, remainingIndices: [Int]) -> Bool {
            guard !remainingIndices.isEmpty else { return true }
            let range = reachableRange(lo: Double(accumulator), hi: Double(accumulator), remainingIndices: remainingIndices)
            let targetValue = Double(target)
            let epsilon = 1e-6
            return targetValue >= range.lo - epsilon && targetValue <= range.hi + epsilon
        }

        private func reachableRange(lo: Double, hi: Double, remainingIndices: [Int]) -> (lo: Double, hi: Double) {
            guard !remainingIndices.isEmpty else { return (lo, hi) }

            var resultLo = Double.infinity
            var resultHi = -Double.infinity

            for position in remainingIndices.indices {
                let dieIndex = remainingIndices[position]
                var dieLo = Double.infinity
                var dieHi = -Double.infinity
                for variant in variantSets[dieIndex] {
                    let value = Double(variant.value)
                    dieLo = min(dieLo, value)
                    dieHi = max(dieHi, value)
                }
                guard dieLo.isFinite else { continue }

                let addLo = lo + dieLo, addHi = hi + dieHi
                let subLo = lo - dieHi, subHi = hi - dieLo
                let products = [lo * dieLo, lo * dieHi, hi * dieLo, hi * dieHi]
                var newLo = min(addLo, subLo, products.min()!)
                var newHi = max(addHi, subHi, products.max()!)
                if dieLo > 0 {
                    let quotients = [lo / dieLo, lo / dieHi, hi / dieLo, hi / dieHi]
                    newLo = min(newLo, quotients.min()!)
                    newHi = max(newHi, quotients.max()!)
                }

                var rest = remainingIndices
                rest.remove(at: position)
                let sub = reachableRange(lo: newLo, hi: newHi, remainingIndices: rest)
                resultLo = min(resultLo, sub.lo)
                resultHi = max(resultHi, sub.hi)
            }

            return (resultLo, resultHi)
        }
    }
}
