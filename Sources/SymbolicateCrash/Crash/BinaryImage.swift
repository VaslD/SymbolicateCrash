import Foundation

/*
struct BinaryImage: Identifiable {
    let id: UInt64
    
    init?(_ string: String) {
        guard let match = try? #/\s+0x([0-9a-f]+) -\s+0x([0-9a-f]+) [0-9A-Za-z\.\-_\+]+ arm64e?\s+<([0-9a-f]+)> (\S*)/#
            .wholeMatch(in: string) else { return nil }
        self.id = UInt64(match.1, radix: 16)!
    }
}
*/
