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

        let variantSets: [[DieValue]] = configuration.dice.map { face in
            DieValue(base: face).variants(
                maxExponent: configuration.maxExponent,
                allowExponents: configuration.allowExponents,
                allowRoots: configuration.allowRoots
            )
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
                    solutions.append(
                        Solution(
                            result: result,
                            dice: chosenDice,
                            operations: chosenOperations,
                            tier: Self.tier(for: chosenDice)
                        )
                    )
                    foundSinceLastYield += 1
                    if foundSinceLastYield >= 25 {
                        continuation.yield(.progress(count: solutions.count))
                        foundSinceLastYield = 0
                        await Task.yield()
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
                            if let next = operation.apply(accumulator, variant.value) {
                                chosenOperations.append(operation)
                                await step(accumulator: next, continuation: continuation)
                                chosenOperations.removeLast()
                            }
                        }
                    } else {
                        await step(accumulator: variant.value, continuation: continuation)
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
