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
}
