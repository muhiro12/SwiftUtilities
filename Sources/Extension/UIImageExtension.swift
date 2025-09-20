//
//  UIImageExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/04/24.
//

import SwiftUI

#if canImport(UIKit)
public extension UIImage {
    /// The primary application icon image resolved from the bundle, or an empty image when unavailable.
    static var appIcon: UIImage {
        guard let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.last else {
            return .init()
        }
        return .init(named: iconName) ?? .init()
    }
}
#endif
