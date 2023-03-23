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
}
