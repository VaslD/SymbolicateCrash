import Foundation
import Logging

let isTTY = ProcessInfo.processInfo.environment["TERM"] != "dumb" && isatty(fileno(stdout)) == 1

struct TerminalLogHandler: LogHandler {
    let label: String
    
    init(label: String) {
        self.label = label
        self.logLevel = isTTY ? .debug : .info
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
        if level < .info, !isTTY { return }
        print(message)
    }
}
