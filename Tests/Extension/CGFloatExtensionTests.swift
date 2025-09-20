import Testing
@testable import SwiftUtilities
import SwiftUI

@Suite("CGFloat Scale helpers")
struct CGFloatExtensionTests {
    @Test
    func spaceValues() {
        #expect(CGFloat.space(.xs) == 4)
        #expect(CGFloat.space(.s) == 8)
        #expect(CGFloat.space(.m) == 16)
        #expect(CGFloat.space(.l) == 32)
        #expect(CGFloat.space(.xl) == 40)
    }

    @Test
    func iconValues() {
        #expect(CGFloat.icon(.xs) == 4)
        #expect(CGFloat.icon(.s) == 8)
        #expect(CGFloat.icon(.m) == 40)
        #expect(CGFloat.icon(.l) == 48)
        #expect(CGFloat.icon(.xl) == 64)
    }

    @Test
    func componentValues() {
        #expect(CGFloat.component(.xs) == 64)
        #expect(CGFloat.component(.s) == 80)
        #expect(CGFloat.component(.m) == 120)
        #expect(CGFloat.component(.l) == 240)
        #expect(CGFloat.component(.xl) == 320)
    }
}

