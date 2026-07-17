// By Ahmed Raslan ®

import os

/// Thin wrapper over `os.Logger` so call sites don't depend on `os` directly
/// and the subsystem stays consistent across modules.
public struct AppLogger: Sendable {
    private let logger: Logger

    /// - Parameter category: Typically the module or type name, e.g. `"Networking"`.
    public init(category: String, subsystem: String = "com.rasslan.github.TMDB") {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String) {
        logger.debug("\(message, privacy: .public)")
    }

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    public func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
