/// Rolls raw dice faces under the game's house rule: at most one face may show a 1 (rerolling
/// until that holds), since the game is difficult to play with two 1s and a third number.
/// Shared by Solve mode's Roll button and Practice mode's puzzle generator, which both need it.
public enum DiceRoller {
    public static func roll(
        count: Int = SolverConfiguration.classicDiceCount,
        sides: Int = SolverConfiguration.classicDiceSides,
        using generator: inout some RandomNumberGenerator
    ) -> [Int] {
        var faces: [Int]
        repeat {
            faces = (0..<count).map { _ in Int.random(in: 1...sides, using: &generator) }
        } while faces.filter({ $0 == 1 }).count > 1
        return faces
    }

    public static func roll(
        count: Int = SolverConfiguration.classicDiceCount,
        sides: Int = SolverConfiguration.classicDiceSides
    ) -> [Int] {
        var generator = SystemRandomNumberGenerator()
        return roll(count: count, sides: sides, using: &generator)
    }
}
