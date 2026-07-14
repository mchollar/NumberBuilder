/// A single piece of a `Solution`'s expression, for a view layer to lay out (e.g. rendering a
/// `DieValue`'s exponent/root as a real superscript instead of concatenating unicode glyphs).
public enum ExpressionToken: Sendable, Hashable {
    case number(DieValue)
    case op(MathOperation)
    case openParen
    case closeParen
    case equals(Int)
}
