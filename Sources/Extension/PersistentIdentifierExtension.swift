//
//  PersistentIdentifierExtension.swift
//  SwiftUtilities
//
//  Created by Hiromu Nakano on 2025/06/17.
//

import Foundation
import SwiftData

public extension PersistentIdentifier {
    init(base64Encoded string: String) throws {
        guard let data = Data(base64Encoded: string) else {
            throw SwiftUtilitiesError.invalidBase64String
        }
        self = try JSONDecoder().decode(Self.self, from: data)
    }

    func base64Encoded() throws -> String {
        try JSONEncoder().encode(self).base64EncodedString()
    }
}
