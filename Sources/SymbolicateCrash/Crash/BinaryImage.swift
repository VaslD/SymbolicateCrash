import Foundation

struct BinaryImage: Identifiable {
    let id: UUID
    let name: String
    let image: UInt64
    let architecture: String
    let path: URL

    init?(_ string: String) {
        guard let match = try? #/\s+0x([0-9a-f]+) -\s+0x([0-9a-f]+) ([0-9A-Za-z\.\-_\+]+) (arm64e?)\s+<([0-9a-f]+)> (\S*)/#
            .wholeMatch(in: string) else { return nil }
        var id = String(match.5.uppercased())
        id.insert("-", at: id.index(id.startIndex, offsetBy: 20))
        id.insert("-", at: id.index(id.startIndex, offsetBy: 16))
        id.insert("-", at: id.index(id.startIndex, offsetBy: 12))
        id.insert("-", at: id.index(id.startIndex, offsetBy: 8))
        self.id = UUID(uuidString: id)!
        self.name = String(match.3)
        self.image = UInt64(match.1, radix: 16)!
        self.architecture = String(match.4)
        self.path = URL(fileURLWithPath: String(match.6))
    }

    func validate(dSYMs: [ArchivedSymbols]) -> Bool {
        guard let dSYM = dSYMs.first(where: { $0.name == self.name }) else { return false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "dwarfdump", "--uuid", dSYM.path.path
        ]
        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "dumb"
        environment["LANG"] = "en_US.UTF-8"
        process.environment = environment
        let pipeOut = Pipe()
        process.standardOutput = pipeOut
        process.standardError = Pipe()
        guard case .success = Result(catching: { try process.run() }) else { return false }
        process.waitUntilExit()
        guard process.terminationStatus == EX_OK else { return false }

        guard let output = try? pipeOut.fileHandleForReading.readToEnd().flatMap({
            String(data: $0, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        }), let match = try? #/UUID: ([0-9A-Z\-]+) \((arm64e?)\)/#.firstMatch(in: output) else { return false }

        return UUID(uuidString: String(match.1))! == self.id && match.2 == self.architecture
    }
}
