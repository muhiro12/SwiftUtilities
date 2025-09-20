//
//  PersistentModelExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import SwiftData

public extension PersistentModel {
    /// Deletes the model instance from its associated model context.
    func delete() {
        modelContext?.delete(self)
    }
}
