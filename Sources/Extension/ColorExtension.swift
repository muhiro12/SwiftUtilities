//
//  ColorExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

import CoreGraphics
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

public extension Color {
    /// Returns a random color with RGB components in the range `0...1`.
    static func random() -> Self {
        return Self(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }

    /// Returns a color that is shifted away from the receiver by the specified percentage.
    ///
    /// - Parameter percentage:
    ///   - `0` means "no change" (the original color).
    ///   - `100` means "full adjustment" (the strongest built-in shift for this color).
    ///   - Values outside `0...100` are clamped.
    /// - Returns: A color blended between the original and its fully-adjusted variant.
    func adjusted(by percentage: Double) -> Self {
        guard let components = Self.srgbComponents(from: self) else {
            return self
        }

        let adjusted = Self.adjustedSRGBComponents(
            red: components.red,
            green: components.green,
            blue: components.blue,
            percentage: percentage
        )

        return Color(
            red: adjusted.red,
            green: adjusted.green,
            blue: adjusted.blue,
            opacity: components.opacity
        )
    }

    static func adjustedSRGBComponents(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        percentage: Double
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let amount = normalizedPercentage(percentage)
        guard amount > 0 else {
            return (red: red, green: green, blue: blue)
        }

        let fullyAdjusted = fullAdjustedSRGBComponents(
            red: red,
            green: green,
            blue: blue
        )

        guard amount < 1 else {
            return fullyAdjusted
        }

        return (
            red: blend(from: red, to: fullyAdjusted.red, amount: amount),
            green: blend(from: green, to: fullyAdjusted.green, amount: amount),
            blue: blend(from: blue, to: fullyAdjusted.blue, amount: amount)
        )
    }

    private static func fullAdjustedSRGBComponents(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let hsv = rgbToHSV(red: red, green: green, blue: blue)

        // Rotate hue to keep high-saturation colors within a nearby family
        // (e.g. red -> yellowish orange at 100%) while still separating categories.
        let hueShift: CGFloat = hsv.saturation < 0.15 ? 0.26 : 0.11
        let adjustedHue = wrappedUnit(hsv.hue + hueShift)

        // Lift saturation so low-chroma colors do not collapse into near-gray variants.
        let adjustedSaturation = clamp(max(hsv.saturation + 0.18, 0.45), lower: 0, upper: 1)

        // Move brightness away from the current level to improve side-by-side distinction.
        let brightnessDelta: CGFloat = hsv.brightness >= 0.55 ? -0.18 : 0.18
        let adjustedBrightness = clamp(hsv.brightness + brightnessDelta, lower: 0.25, upper: 1)

        return hsvToRGB(
            hue: adjustedHue,
            saturation: adjustedSaturation,
            brightness: adjustedBrightness
        )
    }

    private static func normalizedPercentage(_ percentage: Double) -> CGFloat {
        return clamp(CGFloat(percentage / 100), lower: 0, upper: 1)
    }

    private static func blend(from: CGFloat, to: CGFloat, amount: CGFloat) -> CGFloat {
        return from + (to - from) * amount
    }

    private static func srgbComponents(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat)? {
        if
            let cgColor = color.cgColor,
            let components = srgbComponents(from: cgColor)
        {
            return components
        }

        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        return (red: red, green: green, blue: blue, opacity: alpha)
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        guard let srgbColor = nsColor.usingColorSpace(.sRGB) else {
            return nil
        }
        return (
            red: srgbColor.redComponent,
            green: srgbColor.greenComponent,
            blue: srgbColor.blueComponent,
            opacity: srgbColor.alphaComponent
        )
        #else
        return nil
        #endif
    }

    private static func srgbComponents(from cgColor: CGColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat)? {
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        let srgbColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil)
            ?? cgColor

        guard
            let components = srgbColor.components,
            components.count >= 3
        else {
            return nil
        }

        return (
            red: components[0],
            green: components[1],
            blue: components[2],
            opacity: srgbColor.alpha
        )
    }

    private static func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        return min(max(value, lower), upper)
    }

    private static func wrappedUnit(_ value: CGFloat) -> CGFloat {
        let wrapped = value.truncatingRemainder(dividingBy: 1)
        return wrapped < 0 ? wrapped + 1 : wrapped
    }

    private static func rgbToHSV(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat
    ) -> (hue: CGFloat, saturation: CGFloat, brightness: CGFloat) {
        let maximum = max(red, max(green, blue))
        let minimum = min(red, min(green, blue))
        let delta = maximum - minimum

        var hue: CGFloat = 0
        if delta > 0 {
            if maximum == red {
                hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maximum == green {
                hue = ((blue - red) / delta) + 2
            } else {
                hue = ((red - green) / delta) + 4
            }

            hue /= 6
            if hue < 0 {
                hue += 1
            }
        }

        let saturation = maximum == 0 ? 0 : delta / maximum
        return (hue: hue, saturation: saturation, brightness: maximum)
    }

    private static func hsvToRGB(
        hue: CGFloat,
        saturation: CGFloat,
        brightness: CGFloat
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let wrappedHue = wrappedUnit(hue)
        let scaledHue = wrappedHue * 6
        let sector = Int(floor(scaledHue))
        let fraction = scaledHue - CGFloat(sector)

        let p = brightness * (1 - saturation)
        let q = brightness * (1 - saturation * fraction)
        let t = brightness * (1 - saturation * (1 - fraction))

        switch sector % 6 {
        case 0: return (red: brightness, green: t, blue: p)
        case 1: return (red: q, green: brightness, blue: p)
        case 2: return (red: p, green: brightness, blue: t)
        case 3: return (red: p, green: q, blue: brightness)
        case 4: return (red: t, green: p, blue: brightness)
        default: return (red: brightness, green: p, blue: q)
        }
    }
}
