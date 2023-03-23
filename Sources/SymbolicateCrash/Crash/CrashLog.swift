import Foundation

struct CrashLog {
    var lines: [String]

    init?(_ file: URL) {
        guard case let .success(data) = Result(catching: { try Data(contentsOf: file, options: .mappedIfSafe) }),
              let lines = String(data: data, encoding: .utf8)?.components(separatedBy: "\n") else {
            return nil
        }
        self.lines = lines
    }

    @discardableResult
    mutating func symbolicate(archive: XcodeArchive) -> [(binary: String, address: String, isSymbolicated: Bool)] {
        var results = [(String, String, Bool)]()
        var replacements = [(Int, String)]()
        for (index, line) in self.lines.enumerated() {
            guard var frame = StackFrame(line) else { continue }

            guard frame.symbolicate(archive: archive),
                  frame.description != line else {
                results.append((frame.binaryName, "0x\(String(frame.symbolAddress, radix: 16))", false))
                continue
            }
            results.append((frame.binaryName, "0x\(String(frame.symbolAddress, radix: 16))", true))
            replacements.append((index, frame.description))
        }
        for (index, line) in replacements {
            self.lines[index] = line
        }
        return results
    }

    func validate(archive: XcodeArchive) -> [(id: UUID, image: String, matches: Bool)] {
        var images = [BinaryImage]()
        var shouldRead = false
        for line in self.lines {
            guard shouldRead else {
                if line == "Binary Images:" {
                    shouldRead = true
                }
                continue
            }

            guard !line.isEmpty else {
                shouldRead = false
                break
            }

            images.append(BinaryImage(line)!)
        }
        return images.map { ($0.id, $0.name, $0.validate(dSYMs: archive.dSYMs)) }.sorted { $0.image < $1.image }
    }
}

// MARK: CustomStringConvertible

extension CrashLog: CustomStringConvertible {
    var description: String {
        self.lines.joined(separator: "\n")
    }
}
