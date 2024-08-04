//
//  Data.swift
//  AppQuizSwift
//
//  Created by Emirhan Demir on 03.08.24.
//

import Foundation
import SwiftData

/// Represents a quiz module with a unique identifier, name, and collection of questions.
struct Module: Identifiable, Codable {
    /// The unique identifier for the module.
    var id: String
    
    /// The name of the module.
    var name: String
    
    /// A list of questions contained within the module.
    var questions: [Question]
}

/// Represents a question within a module, identifiable by a unique identifier.
struct Question: Identifiable, Codable {
    /// The unique identifier for the question.
    var id: String
    
    /// The text of the question.
    var questionText: String
    
    /// The answer to the question.
    var answer: String
}
