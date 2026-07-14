/// The four operations available when combining dice, matching Number Knockout's own vocabulary
/// (addition, subtraction, multiplication, division — exponents and roots live on `DieValue`).
public enum MathOperation: CaseIterable, Sendable, Hashable {
    case add, subtract, multiply, divide

    public var symbol: String {
        switch self {
        case .add: return "+"
        case .subtract: return "-"
        case .multiply: return "×"
        case .divide: return "÷"
        }
    }

    /// `nil` if the operation has no valid integer result (division must be exact).
    public func apply(_ lhs: Int, _ rhs: Int) -> Int? {
        switch self {
        case .add: return lhs + rhs
        case .subtract: return lhs - rhs
        case .multiply: return lhs * rhs
        case .divide:
            guard rhs != 0, lhs % rhs == 0 else { return nil }
            return lhs / rhs
        }
    }
}
