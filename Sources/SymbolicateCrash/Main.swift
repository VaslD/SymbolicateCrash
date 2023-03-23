import ArgumentParser
import Foundation
import Logging
import TabularData

@main
struct SymbolicateCrashCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Symbolicate *.crash with dSYMs from *.xcarchive.",
        version: "1.0.1"
    )

    @Argument(help: "Path to an *.xcarchive bundle.")
    var archive: URL

    @Argument(help: "Path to a *.crash file.")
    var crashLog: URL

    @Argument(help: "Path to output file; otherwise write to standard out.")
    var output: URL?

    func run() async throws {
        LoggingSystem.bootstrap(TerminalLogHandler.init(label:))
        let logger = Logger(label: "SymbolicateCrashCommand")

        let files = FileManager.default
        guard files.fileExists(atPath: archive.path), files.fileExists(atPath: self.crashLog.path) else {
            throw POSIXError(.ENOENT)
        }

        logger.trace("Reading Xcode archive…")
        let archive = try XcodeArchive(self.archive)
        logger.trace("\(archive)")
        logger.trace("")

        logger.trace("Reading crash log…")
        var log = CrashLog(self.crashLog)!
        logger.trace("Read \(log.description.count) lines")
        logger.trace("")

        logger.trace("Looking up symbols…")
        let results = log.symbolicate(archive: archive)
        logger.trace("")

        var summary = DataFrame()
        summary.append(column: Column<String>(name: "Binary", capacity: results.count))
        summary.append(column: Column<String>(name: "Symbol", capacity: results.count))
        summary.append(column: Column<String>(name: "Result", capacity: results.count))
        for result in results {
            summary.append(row: result.binary, result.address, result.isSymbolicated ? "OK" : String())
        }
        var options = FormattingOptions()
        options.maximumRowCount = results.count
        options.includesColumnTypes = false
        logger.debug("\(summary.description(options: options))")

        if let file = self.output,
           case .success = Result(catching: { try log.description.data(using: .utf8)!.write(to: file) }) {
            return
        }
        logger.info("\(log)")
    }
}
