//
//  Item.swift
//  s
//
//  Created by Emirhan Demir on 03.08.24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
