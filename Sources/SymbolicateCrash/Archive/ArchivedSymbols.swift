import Foundation

struct ArchivedSymbols: Identifiable, Decodable {
    let id: String
    let version: String
    let build: String
    private(set) var name: String!
    private(set) var path: URL!
    
    enum CodingKeys: String, CodingKey {
        case id = "CFBundleIdentifier"
        case version = "CFBundleShortVersionString"
        case build = "CFBundleVersion"
        case path
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
    }
}
