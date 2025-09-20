//
//  ViewExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 9/26/24.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func hidden(_ hidden: Bool = true) -> some View {
        if !hidden {
            self
        }
    }

    func singleLine(minScaleFactor: CGFloat = 0.5) -> some View {
        lineLimit(1)
            .minimumScaleFactor(minScaleFactor)
    }

    func twoLines(minScaleFactor: CGFloat = 0.5) -> some View {
        lineLimit(2)
            .minimumScaleFactor(minScaleFactor)
    }
}
