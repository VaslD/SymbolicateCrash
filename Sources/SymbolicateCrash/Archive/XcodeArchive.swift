import Foundation

struct XcodeArchive: Decodable {
    let version: Int
    let name: String
    let scheme: String
    let date: Date
    let application: ArchivedApplication
    private(set) var dSYMs: [ArchivedSymbols]!
    
    enum CodingKeys: String, CodingKey {
        case version = "ArchiveVersion"
        case name = "Name"
        case scheme = "SchemeName"
        case date = "CreationDate"
        case application = "ApplicationProperties"
        case dSYMs
    }
    
    init(_ archive: URL) throws {
        let info = try Data(contentsOf: archive.appendingPathComponent("Info.plist", isDirectory: false),
                            options: .mappedIfSafe)
        self = try PropertyListDecoder().decode(Self.self, from: info)
        
        let dSYMs = try FileManager.default.contentsOfDirectory(
            at: archive.appendingPathComponent("dSYMs", isDirectory: true),
            includingPropertiesForKeys: nil
        )
        self.dSYMs = try dSYMs.map { try ArchivedSymbols($0) }
    }
}

extension XcodeArchive: CustomStringConvertible {
    var description: String {
        """
        → Xcode Archive (\(self.name))
          Date:      \(self.date)
          Bundle ID: \(self.application.id)
          Version:   \(self.application.version) (\(self.application.build))
          dSYMs:     \(self.dSYMs.count)
        """
    }
}
