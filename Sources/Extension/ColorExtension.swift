//
//  ColorExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

public extension Color {
    /// Returns a random color with RGB components in the range `0...1`.
    static func random() -> Self {
        return Self(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }

    @MainActor
    /// Returns a color derived by adjusting the base color using a reproducible integer seed.
    /// - Parameter adjustmentValue: An integer seed used to perturb RGB channels.
    /// - Returns: A color adjusted from the receiver using the provided seed.
    func adjusted(by adjustmentValue: Int) -> Self {
        modifier(
            AdjustmentModifier(
                baseColor: self,
                adjustmentValue: adjustmentValue
            )
        ) as? Self ?? self
    }

    /// A view modifier that deterministically adjusts a color based on an integer seed.
    struct AdjustmentModifier: ViewModifier {
        @Environment(\.self) private var environment

        let baseColor: Color
        let adjustmentValue: Int

        /// Applies the modifier and returns an adjusted color.
        public func body(content: Content) -> some View {
            guard let components = baseColor.resolve(in: environment).cgColor.components, components.count >= 3 else {
                return baseColor
            }

            let red = components[0]
            let green = components[1]
            let blue = components[2]

            let redAdjustment = CGFloat(adjustmentValue % 61 - 30)
            let greenAdjustment = CGFloat((adjustmentValue / 61) % 61 - 30)
            let blueAdjustment = CGFloat((adjustmentValue / (61 * 61)) % 61 - 30)

            let newRed = min(max(red + redAdjustment / 255, 0), 1)
            let newGreen = min(max(green + greenAdjustment / 255, 0), 1)
            let newBlue = min(max(blue + blueAdjustment / 255, 0), 1)

            return Color(red: newRed, green: newGreen, blue: newBlue)
        }
    }
}
