import CoreGraphics
import Testing
@testable import SwiftUtilities
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

@Suite("Color adjusted(by:)")
struct ColorExtensionTests {
    typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat)

    @Test
    func adjustedByReturnsDifferentColorForPureRed() {
        guard
            let base = srgbComponents(from: Color.red),
            let adjusted = srgbComponents(from: Color.red.adjusted(by: 1))
        else {
            Issue.record("Failed to resolve sRGB components from Color.")
            return
        }

        #expect(distance(base, adjusted) > 0.20)
    }

    @Test
    func adjustedComponentsStayInBounds() {
        for adjustmentValue in stride(from: -256, through: 256, by: 17) {
            let adjusted = Color.adjustedSRGBComponents(
                red: 0.92,
                green: 0.08,
                blue: 0.13,
                adjustmentValue: adjustmentValue
            )

            #expect(adjusted.red >= 0 && adjusted.red <= 1)
            #expect(adjusted.green >= 0 && adjusted.green <= 1)
            #expect(adjusted.blue >= 0 && adjusted.blue <= 1)
        }
    }

    @Test
    func pureRedVariantsAreVisiblySeparated() {
        let base: RGB = (red: 1, green: 0, blue: 0)
        let variants = (0..<8).map {
            Color.adjustedSRGBComponents(
                red: base.red,
                green: base.green,
                blue: base.blue,
                adjustmentValue: $0
            )
        }

        let minimumDistanceFromBase = variants.map { distance(base, $0) }.min() ?? 0
        #expect(minimumDistanceFromBase > 0.20)
        #expect(minPairwiseDistance(variants) > 0.20)
    }

    @Test
    func grayVariantsAreStillDistinguishable() {
        let base: RGB = (red: 0.4, green: 0.4, blue: 0.4)
        let variants = (0..<8).map {
            Color.adjustedSRGBComponents(
                red: base.red,
                green: base.green,
                blue: base.blue,
                adjustmentValue: $0
            )
        }

        let minimumDistanceFromBase = variants.map { distance(base, $0) }.min() ?? 0
        #expect(minimumDistanceFromBase > 0.10)
        #expect(minPairwiseDistance(variants) > 0.04)

        for variant in variants {
            let spread = max(variant.red, max(variant.green, variant.blue))
                - min(variant.red, min(variant.green, variant.blue))
            #expect(spread > 0.02)
        }
    }

    @Test
    func adjustedComponentsAreDeterministic() {
        let first = Color.adjustedSRGBComponents(
            red: 0.18,
            green: 0.36,
            blue: 0.72,
            adjustmentValue: 42
        )
        let second = Color.adjustedSRGBComponents(
            red: 0.18,
            green: 0.36,
            blue: 0.72,
            adjustmentValue: 42
        )

        #expect(distance(first, second) < 0.000_001)
    }

    private func srgbComponents(from color: Color) -> RGB? {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return (red: red, green: green, blue: blue)
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        guard let srgbColor = nsColor.usingColorSpace(.sRGB) else {
            return nil
        }
        return (
            red: srgbColor.redComponent,
            green: srgbColor.greenComponent,
            blue: srgbColor.blueComponent
        )
        #else
        return nil
        #endif
    }

    private func distance(_ lhs: RGB, _ rhs: RGB) -> CGFloat {
        let redDelta = lhs.red - rhs.red
        let greenDelta = lhs.green - rhs.green
        let blueDelta = lhs.blue - rhs.blue
        return sqrt(redDelta * redDelta + greenDelta * greenDelta + blueDelta * blueDelta)
    }

    private func minPairwiseDistance(_ values: [RGB]) -> CGFloat {
        var minimum = CGFloat.greatestFiniteMagnitude
        for leftIndex in values.indices {
            for rightIndex in values.indices where rightIndex > leftIndex {
                minimum = min(minimum, distance(values[leftIndex], values[rightIndex]))
            }
        }
        return minimum
    }
}
