//
//  CGFloatExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/09/20.
//

import SwiftUI

extension CGFloat {
    public enum Scale {
        case xs
        case s
        case m
        case l
        case xl
    }

    private static let unit = Self(8)

    public static func space(_ size: Scale) -> Self {
        switch size {
        case .xs:
            unit * 0.5
        case .s:
            unit * 1
        case .m:
            unit * 2
        case .l:
            unit * 4
        case .xl:
            unit * 5
        }
    }

    public static func icon(_ size: Scale) -> Self {
        switch size {
        case .xs:
            unit * 1
        case .s:
            unit * 2
        case .m:
            unit * 3
        case .l:
            unit * 5
        case .xl:
            unit * 6
        }
    }

    public static func component(_ size: Scale) -> Self {
        switch size {
        case .xs:
            unit * 8
        case .s:
            unit * 10
        case .m:
            unit * 15
        case .l:
            unit * 30
        case .xl:
            unit * 40
        }
    }
}
