//
//  ColorExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/18/24.
//

import SwiftUI

public extension Color {
    static func random() -> Self {
        return Self(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }

    @MainActor
    func adjusted(by adjustmentValue: Int) -> Self {
        modifier(
            AdjustmentModifier(
                baseColor: self,
                adjustmentValue: adjustmentValue
            )
        ) as? Self ?? self
    }

    struct AdjustmentModifier: ViewModifier {
        @Environment(\.self) private var environment

        let baseColor: Color
        let adjustmentValue: Int

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
