//
//  PersistentIdentifierExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import Foundation
import SwiftData

public extension PersistentIdentifier {
    /// Creates a persistent identifier by decoding a Base64-encoded JSON representation.
    /// - Parameter string: A Base64-encoded string created by ``base64Encoded()``.
    /// - Throws: ``SwiftUtilitiesError/invalidBase64String`` if decoding the Base64 string fails.
    init(base64Encoded string: String) throws {
        guard let data = Data(base64Encoded: string) else {
            throw SwiftUtilitiesError.invalidBase64String
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    /// Encodes this identifier as JSON and returns a Base64-encoded string.
    /// - Returns: A Base64-encoded JSON string.
    func base64Encoded() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }
}
