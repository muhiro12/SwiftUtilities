//
//  ImageExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/04/23.
//

import SwiftUI

public extension Image {
    init(data: Data) {
        if let uiImage = UIImage(data: data) {
            self = .init(uiImage: uiImage)
        } else {
            self = .init(.empty)
        }
    }
}
