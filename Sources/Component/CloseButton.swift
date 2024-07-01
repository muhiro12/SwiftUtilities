//
//  CloseButton.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import SwiftUI

public struct CloseButton: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    public var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(
                    Color(.secondaryLabel),
                    Color(.secondarySystemFill)
                )
                .font(.title)
        }
    }
}

#Preview {
    CloseButton()
}
