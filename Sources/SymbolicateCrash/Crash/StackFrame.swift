import Foundation

struct StackFrame {
    let original: String
    
    let binaryName: String
    let symbolAddress: UInt64
    let binaryImage: UInt64
    let offset: Int
    
    private(set) var symbol: String?
    
    init?(_ string: String) {
        guard let match = try? #/\d+\s+([0-9A-Za-z\.\-_\+]+)\s+0x([0-9a-f]+) 0x([0-9a-f]+) \+ (\d+)/#
            .wholeMatch(in: string) else { return nil }
        
        self.original = string
        self.binaryName = String(match.1)
        self.symbolAddress = UInt64(match.2, radix: 16)!
        self.binaryImage = UInt64(match.3, radix: 16)!
        self.offset = Int(match.4)!
    }
    
    @discardableResult
    mutating func symbolicate(dSYMs: [DebugSymbols]) -> Bool {
        guard let dSYM = dSYMs.first(where: { $0.name == self.binaryName }) else { return false }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "atos", "-arch", dSYM.architecture,
            "-o", dSYM.path.path,
            "-l", "0x\(String(self.binaryImage, radix: 16))", "0x\(String(self.symbolAddress, radix: 16))"
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
        }) else { return false }
        
        self.symbol = output
        return true
    }
}

extension StackFrame: CustomStringConvertible {
    var description: String {
        guard let symbol = self.symbol else { return self.original }
        return self.original.replacingOccurrences(
            of: "0x\(String(self.binaryImage, radix: 16)) + \(self.offset)",
            with: symbol
        )
    }
}
