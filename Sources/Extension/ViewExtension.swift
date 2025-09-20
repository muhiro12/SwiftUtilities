//
//  ViewExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/26/24.
//

import SwiftUI

public extension View {
    /// Conditionally hides the view by omitting it from the hierarchy when `hidden` is `true`.
    /// - Parameter hidden: Whether to hide the view. Defaults to `true`.
    /// - Returns: The original view when `hidden` is `false`; otherwise an empty view.
    @ViewBuilder
    func hidden(_ hidden: Bool = true) -> some View {
        if !hidden {
            self
        }
    }

    /// Constrains the text to a single line and applies a minimum scale factor.
    /// - Parameter minScaleFactor: The minimum scale factor to apply. Defaults to `0.5`.
    func singleLine(minScaleFactor: CGFloat = 0.5) -> some View {
        lineLimit(1)
            .minimumScaleFactor(minScaleFactor)
    }

    /// Constrains the text to two lines and applies a minimum scale factor.
    /// - Parameter minScaleFactor: The minimum scale factor to apply. Defaults to `0.5`.
    func twoLines(minScaleFactor: CGFloat = 0.5) -> some View {
        lineLimit(2)
            .minimumScaleFactor(minScaleFactor)
    }
}
