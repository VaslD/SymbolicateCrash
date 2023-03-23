import Foundation
import Logging

let isTTY = ProcessInfo.processInfo.environment["TERM"] != "dumb" && isatty(fileno(stdout)) == 1

struct TerminalLogHandler: LogHandler {
    let label: String

    init(label: String) {
        self.label = label
        self.logLevel = isTTY ? .trace : .info
        self.metadata = [:]
    }

    var logLevel: Logging.Logger.Level

    var metadata: Logging.Logger.Metadata

    subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { self.metadata[key] }
        set { self.metadata[key] = newValue }
    }

    func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?,
             source: String, file: String, function: String, line: UInt) {
        switch level {
        case .trace where isTTY:
            print("\u{001B}[37m\(message)\u{001B}[0m")

        case .debug where isTTY:
            print(message)

        case .info, .notice:
            print(message)

        case .warning where isTTY:
            print("\u{001B}[33m\(message)\u{001B}[0m")

        case .error where isTTY, .critical where isTTY:
            print("\u{001B}[31m\(message)\u{001B}[0m")

        case .critical, .error, .warning:
            print(message)

        default:
            break
        }

        fflush(stdout)
    }
}
