import Foundation

struct ArchivedApplication: Identifiable, Decodable {
    let id: String
    let version: String
    let build: String
    let developerID: String
    let teamID: String
    let path: String
    let architectures: [String]

    enum CodingKeys: String, CodingKey {
        case id = "CFBundleIdentifier"
        case version = "CFBundleShortVersionString"
        case build = "CFBundleVersion"
        case developerID = "SigningIdentity"
        case teamID = "Team"
        case path = "ApplicationPath"
        case architectures = "Architectures"
    }
}
