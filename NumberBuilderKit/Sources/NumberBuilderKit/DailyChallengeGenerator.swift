import Foundation

/// Produces the same roll + target for everyone on a given calendar day (Wordle-style), derived
/// deterministically from the date rather than a server round-trip.
public enum DailyChallengeGenerator {
    public struct Challenge: Sendable, Hashable {
        public let dice: [Int]
        public let target: Int
    }

    public static func challenge(
        for date: Date,
        diceCount: Int = SolverConfiguration.classicDiceCount,
        diceSides: Int = SolverConfiguration.classicDiceSides
    ) -> Challenge {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        let components = utcCalendar.dateComponents([.year, .month, .day], from: date)
        let dayString = String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )

        var generator = SplitMix64(seed: StableHash.fnv1a(dayString))

        let dice = (0..<diceCount).map { _ in
            Int(generator.next() % UInt64(diceSides)) + 1
        }

        // The classic 3d6 board is numbered 1...36 — sides² generalizes that to other dice.
        let maxTarget = diceSides * diceSides
        let target = Int(generator.next() % UInt64(maxTarget)) + 1

        return Challenge(dice: dice, target: target)
    }
}
