import Foundation

struct DebugSymbols: Decodable {
    let bundleID: String
    let version: String
    let build: String
    private(set) var id: UUID!
    private(set) var architecture: String!
    private(set) var name: String!
    private(set) var path: URL!
    
    enum CodingKeys: String, CodingKey {
        case bundleID = "CFBundleIdentifier"
        case version = "CFBundleShortVersionString"
        case build = "CFBundleVersion"
    }
    
    init(_ dSYM: URL) throws {
        let info = try Data(
            contentsOf: dSYM.appendingPathComponent("Contents", isDirectory: true)
                .appendingPathComponent("Info.plist", isDirectory: false),
            options: .mappedIfSafe
        )
        self = try PropertyListDecoder().decode(Self.self, from: info)
        
        let binary = try FileManager.default.contentsOfDirectory(
            at: dSYM.appendingPathComponent("Contents", isDirectory: true)
                .appendingPathComponent("Resources", isDirectory: true)
                .appendingPathComponent("DWARF", isDirectory: true),
            includingPropertiesForKeys: nil
        )
        guard binary.count == 1 else {
            fatalError("FIX ME")
        }
        self.path = binary.first!
        self.name = self.path.lastPathComponent

        try self.analyze()
    }

    mutating func analyze() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "dwarfdump", "--uuid", self.path.path
        ]
        var environment = ProcessInfo.processInfo.environment
        environment["TERM"] = "dumb"
        environment["LANG"] = "en_US.UTF-8"
        process.environment = environment
        let pipeOut = Pipe()
        process.standardOutput = pipeOut
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == EX_OK else {
            throw CocoaError(.fileReadUnknown)
        }

        guard let output = try? pipeOut.fileHandleForReading.readToEnd().flatMap({
            String(data: $0, encoding: .utf8)?.trimmingCharacters(in: .newlines)
        }), let match = try? #/UUID: ([0-9A-Z\-]+) \((arm64e?)\)/#.firstMatch(in: output) else {
            fatalError("FIX ME")
        }

        self.id = UUID(uuidString: String(match.1))!
        self.architecture = String(match.2)
    }
}
