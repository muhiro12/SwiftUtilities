import Testing
@testable import SwiftUtilities

@Suite("Collection/Optional Extensions")
struct CollectionOptionalExtensionTests {
    @Test
    func collectionEmptyAndIsNotEmpty() {
        let emptyArray = [Int].empty
        #expect(emptyArray.isEmpty)
        #expect(!emptyArray.isNotEmpty)

        let array = [1, 2, 3]
        #expect(array.isNotEmpty)
    }

    @Test
    func optionalOrEmptyAndIsNotEmpty() {
        let optionalNone: [Int]? = nil
        #expect(optionalNone.orEmpty.isEmpty)
        #expect(!optionalNone.isNotEmpty)

        let optionalSome: [Int]? = [1]
        #expect(optionalSome.orEmpty.count == 1)
        #expect(optionalSome.isNotEmpty)
    }
}

