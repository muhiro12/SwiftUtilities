import Testing
@testable import SwiftUtilities
import SwiftData

@Suite("PersistentIdentifier base64 decode/encode")
struct PersistentIdentifierExtensionTests {
    @Test
    func invalidBase64StringThrows() async throws {
        #expect(throws: SwiftUtilitiesError.invalidBase64String) {
            _ = try PersistentIdentifier(base64Encoded: "not-a-base64")
        }
    }
}

