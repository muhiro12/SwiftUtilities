//
//  ImageExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/04/23.
//

import SwiftUI

public extension Image {
    #if canImport(UIKit)
    /// Creates an image from raw data, or an empty system image when decoding fails.
    /// - Parameter data: Image data, such as PNG or JPEG.
    init(data: Data) {
        if let uiImage = UIImage(data: data) {
            self = .init(uiImage: uiImage)
        } else {
            self = .init(.empty)
        }
    }
    #endif
}
