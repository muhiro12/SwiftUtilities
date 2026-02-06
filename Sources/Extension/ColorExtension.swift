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

    /// Returns a color derived by adjusting the base color using a reproducible integer seed.
    /// - Parameter adjustmentValue: An integer seed used to perturb hue, saturation, and brightness.
    /// - Returns: A color adjusted from the receiver using the provided seed.
    func adjusted(by adjustmentValue: Int) -> Self {
        guard let components = Self.srgbComponents(from: self) else {
            return self
        }

        let adjusted = Self.adjustedSRGBComponents(
            red: components.red,
            green: components.green,
            blue: components.blue,
            adjustmentValue: adjustmentValue
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
        adjustmentValue: Int
    ) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let hsv = rgbToHSV(red: red, green: green, blue: blue)

        let hueSignal = lowDiscrepancySignal(adjustmentValue, offset: 0.00)
        let saturationSignal = lowDiscrepancySignal(adjustmentValue, offset: 0.31)
        let brightnessSignal = lowDiscrepancySignal(adjustmentValue, offset: 0.63)

        var adjustedHue = wrappedUnit(hsv.hue + hueSignal * 0.40)
        var adjustedSaturation = clamp(
            hsv.saturation + saturationSignal * 0.24,
            lower: 0.25,
            upper: 1
        )
        let adjustedBrightness = clamp(
            hsv.brightness + brightnessSignal * 0.20,
            lower: 0.30,
            upper: 1
        )

        if hsv.saturation < 0.15 {
            adjustedHue = wrappedUnit(CGFloat(Double(adjustmentValue) * 0.3819660112501051))
            adjustedSaturation = max(adjustedSaturation, 0.45)
        }

        return hsvToRGB(
            hue: adjustedHue,
            saturation: adjustedSaturation,
            brightness: adjustedBrightness
        )
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

    private static func lowDiscrepancySignal(_ adjustmentValue: Int, offset: Double) -> CGFloat {
        let raw = Double(adjustmentValue) * 0.618033988749895 + offset
        let fractional = raw - floor(raw)
        let signed = CGFloat(fractional * 2 - 1)
        return curve(signed)
    }

    private static func curve(_ value: CGFloat) -> CGFloat {
        let magnitude = pow(abs(value), 0.8)
        return value < 0 ? -magnitude : magnitude
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
