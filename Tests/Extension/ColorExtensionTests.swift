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

@Suite("Color adjusted(by percentage)")
struct ColorExtensionTests {
    typealias RGB = (red: CGFloat, green: CGFloat, blue: CGFloat)

    @Test
    func adjustedByReturnsDifferentColorForPureRedAtHundredPercent() {
        guard
            let base = srgbComponents(from: Color.red),
            let adjusted = srgbComponents(from: Color.red.adjusted(by: 100))
        else {
            Issue.record("Failed to resolve sRGB components from Color.")
            return
        }

        #expect(distance(base, adjusted) > 0.20)
    }

    @Test
    func pureRedAtHundredPercentBecomesYellowishOrange() {
        let adjusted = Color.adjustedSRGBComponents(
            red: 1,
            green: 0,
            blue: 0,
            percentage: 100
        )

        #expect(adjusted.red > adjusted.green)
        #expect(adjusted.green > adjusted.blue)
        #expect(adjusted.green > 0.45)
        #expect(adjusted.blue < 0.05)
    }

    @Test
    func zeroPercentageKeepsOriginalColor() {
        let base: RGB = (red: 0.8, green: 0.2, blue: 0.1)
        let adjusted = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 0
        )

        #expect(distance(base, adjusted) < 0.000_001)
    }

    @Test
    func higherPercentageProducesLargerDifference() {
        let base: RGB = (red: 0.8, green: 0.2, blue: 0.1)
        let low = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 25
        )
        let high = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 100
        )

        #expect(distance(base, high) > distance(base, low))
    }

    @Test
    func percentageOverHundredIsClamped() {
        let base: RGB = (red: 0.8, green: 0.2, blue: 0.1)
        let full = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 100
        )
        let over = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 200
        )

        #expect(distance(full, over) < 0.000_001)
    }

    @Test
    func negativePercentageIsClampedToOriginal() {
        let base: RGB = (red: 0.3, green: 0.6, blue: 0.2)
        let adjusted = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: -40
        )

        #expect(distance(base, adjusted) < 0.000_001)
    }

    @Test
    func adjustedComponentsStayInBounds() {
        for percentage in stride(from: -100.0, through: 200.0, by: 7.5) {
            let adjusted = Color.adjustedSRGBComponents(
                red: 0.92,
                green: 0.08,
                blue: 0.13,
                percentage: percentage
            )

            #expect(adjusted.red >= 0 && adjusted.red <= 1)
            #expect(adjusted.green >= 0 && adjusted.green <= 1)
            #expect(adjusted.blue >= 0 && adjusted.blue <= 1)
        }
    }

    @Test
    func fullPercentageIsDistinctForGray() {
        let base: RGB = (red: 0.4, green: 0.4, blue: 0.4)
        let adjusted = Color.adjustedSRGBComponents(
            red: base.red,
            green: base.green,
            blue: base.blue,
            percentage: 100
        )

        #expect(distance(base, adjusted) > 0.10)
    }

    @Test
    func adjustedComponentsAreDeterministic() {
        let first = Color.adjustedSRGBComponents(
            red: 0.18,
            green: 0.36,
            blue: 0.72,
            percentage: 75
        )
        let second = Color.adjustedSRGBComponents(
            red: 0.18,
            green: 0.36,
            blue: 0.72,
            percentage: 75
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
}
