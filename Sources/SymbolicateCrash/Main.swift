import ArgumentParser
import Foundation
import Logging
import TabularData

@main
struct SymbolicateCrashCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Symbolicate *.crash with dSYMs from *.xcarchive.",
        version: "1.1.0"
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

        logger.trace("Validating dSYMs…")
        let dSYMs = log.validate(archive: archive)
        var summary = DataFrame()
        summary.append(column: Column<String>(name: "Binary", capacity: dSYMs.count))
        summary.append(column: Column<String>(name: "UUID", capacity: dSYMs.count))
        summary.append(column: Column<String>(name: "dSYM", capacity: dSYMs.count))
        for result in dSYMs {
            summary.append(row: result.image, result.id.uuidString, result.matches ? "YES" : String())
        }
        var options = FormattingOptions()
        options.maximumRowCount = dSYMs.count
        options.includesColumnTypes = false
        logger.debug("\(summary.description(options: options))")

        logger.trace("Looking up symbols…")
        let results = log.symbolicate(archive: archive)
        summary = DataFrame()
        summary.append(column: Column<String>(name: "Binary", capacity: results.count))
        summary.append(column: Column<String>(name: "Symbol", capacity: results.count))
        summary.append(column: Column<String>(name: "Result", capacity: results.count))
        for result in results {
            summary.append(row: result.binary, result.address, result.isSymbolicated ? "OK" : String())
        }
        options.maximumRowCount = results.count
        logger.debug("\(summary.description(options: options))")

        if let file = self.output,
           case .success = Result(catching: { try log.description.data(using: .utf8)!.write(to: file) }) {
            return
        }
        logger.info("━━━━━━━━━━")
        logger.info("\(log)")
    }
}
