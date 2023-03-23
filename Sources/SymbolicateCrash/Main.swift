import ArgumentParser
import Foundation
import Logging
import TabularData

@main
struct SymbolicateCrashCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Symbolicate *.crash with dSYMs from *.xcarchive.",
        version: "1.1.1"
    )

    @Argument(help: "Path to an *.xcarchive bundle, or the dSYMs directory.")
    var archive: URL

    @Argument(help: "Path to a *.crash file")
    var crashLog: URL

    @Argument(help: "Path to output file; otherwise write to standard output")
    var output: URL?

    func run() throws {
        LoggingSystem.bootstrap(TerminalLogHandler.init(label:))
        let logger = Logger(label: "SymbolicateCrashCommand")

        do { try self.symbolicate(logger: logger) }
        catch {
            logger.error("Error: \(error.localizedDescription)")
            throw ExitCode(EX_SOFTWARE)
        }
    }

    func symbolicate(logger: Logger) throws {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: archive.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              FileManager.default.fileExists(atPath: self.crashLog.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            throw POSIXError(.ENOENT)
        }

        var dSYMs = [DebugSymbols]()

        logger.trace("Reading Xcode archive…")
        if let archive = try? XcodeArchive(self.archive) {
            logger.debug("\(archive)")
            dSYMs = archive.dSYMs
        } else {
            logger.trace("Malformed Xcode archive manifest.")
            logger.trace("Reading dSYMs…")
            for directory in try FileManager.default.contentsOfDirectory(
                at: self.archive,
                includingPropertiesForKeys: [.isDirectoryKey]
            ) where try directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory!
                && directory.pathExtension == "dSYM" {
                guard let dSYM = try? DebugSymbols(directory) else {
                    continue
                }
                dSYMs.append(dSYM)
            }
        }
        guard !dSYMs.isEmpty else {
            logger.error("No dSYMs found. Symbolication impossible.")
            throw ExitCode(EX_NOINPUT)
        }
        logger.trace("")

        logger.trace("Reading crash log…")
        var log = CrashLog(self.crashLog)!
        logger.trace("Read \(log.description.count) lines")
        logger.trace("")

        logger.trace("Validating dSYMs…")
        let validation = log.validate(dSYMs: dSYMs)
        var summary = DataFrame()
        summary.append(column: Column<String>(name: "Binary", capacity: validation.count))
        summary.append(column: Column<String>(name: "UUID", capacity: validation.count))
        summary.append(column: Column<String>(name: "dSYM", capacity: validation.count))
        for result in validation {
            summary.append(row: result.image, result.id.uuidString, result.matches ? "YES" : String())
        }
        var options = FormattingOptions()
        options.maximumRowCount = validation.count
        options.includesColumnTypes = false
        logger.debug("\(summary.description(options: options))")

        logger.trace("Looking up symbols…")
        let results = log.symbolicate(dSYMs: dSYMs)
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
            logger.debug("Symbolicated crash written to: \(file.path)")
            return
        }
        logger.info("━━━━━━━━━━")
        logger.critical("\(log)")
    }
}
