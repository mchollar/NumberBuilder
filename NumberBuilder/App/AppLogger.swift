import Foundation
import os

/// Structured logging via the unified logging system -- safe to ship in Release (unlike
/// `print()`, interpolated values are privacy-redacted by default and nothing prints to the
/// console unless a device is actually attached and someone's watching in Console.app). No
/// in-app viewer; this exists purely so a future debugging session has real signal to read
/// instead of adding temporary `print()`s and stripping them before committing.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "Widgetilities.NumberBuilder"

    static let solve = Logger(subsystem: subsystem, category: "Solve")
    static let practice = Logger(subsystem: subsystem, category: "Practice")
    static let purchase = Logger(subsystem: subsystem, category: "Purchase")
}
