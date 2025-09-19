//
//  UIImageExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/04/24.
//

import SwiftUI

public extension UIImage {
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
