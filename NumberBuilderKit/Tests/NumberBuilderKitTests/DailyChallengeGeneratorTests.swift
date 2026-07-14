import XCTest
@testable import NumberBuilderKit

final class DailyChallengeGeneratorTests: XCTestCase {
    func testSameDateProducesIdenticalChallenge() {
        let date = utcDate(year: 2026, month: 7, day: 13)
        let first = DailyChallengeGenerator.challenge(for: date)
        let second = DailyChallengeGenerator.challenge(for: date)
        XCTAssertEqual(first, second, "The same calendar day must produce the same challenge every time it's computed, on any device.")
    }

    func testDifferentDatesProduceDifferentChallenges() {
        let a = DailyChallengeGenerator.challenge(for: utcDate(year: 2026, month: 7, day: 13))
        let b = DailyChallengeGenerator.challenge(for: utcDate(year: 2026, month: 7, day: 14))
        XCTAssertNotEqual(a, b)
    }

    func testDiceAndTargetAreWithinExpectedRanges() {
        let challenge = DailyChallengeGenerator.challenge(for: utcDate(year: 2026, month: 1, day: 1))
        XCTAssertEqual(challenge.dice.count, SolverConfiguration.classicDiceCount)
        for face in challenge.dice {
            XCTAssertTrue((1...SolverConfiguration.classicDiceSides).contains(face))
        }
        XCTAssertTrue((1...36).contains(challenge.target))
    }

    private func utcDate(year: Int, month: Int, day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
