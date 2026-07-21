/// Reduces `dice`/`operations` left to right, exactly as the physical game is played (no
/// operator precedence) -- the single authoritative evaluator, shared by `SolverEngine`'s search
/// and anything else (e.g. Challenge mode's validator) that needs to check whether a specific
/// sequence of dice and operations reaches a given result. `nil` if the shapes don't line up
/// (wrong operation count) or any step is invalid (overflow, inexact division).
public func evaluate(dice: [DieValue], operations: [MathOperation]) -> Int? {
    guard let first = dice.first else { return nil }
    guard operations.count == dice.count - 1 else { return nil }

    var accumulator = first.value
    for (operation, die) in zip(operations, dice.dropFirst()) {
        guard let next = operation.apply(accumulator, die.value) else { return nil }
        accumulator = next
    }
    return accumulator
}
