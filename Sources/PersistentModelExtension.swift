//
//  PersistentModelExtension.swift
//  
//
//  Created by Hiromu Nakano on 2024/06/29.
//

import SwiftData

public extension PersistentModel {
    func delete() {
        modelContext?.delete(self)
    }
}
