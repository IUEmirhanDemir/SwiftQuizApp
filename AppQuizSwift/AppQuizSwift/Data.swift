//
//  Data.swift
//  AppQuizSwift
//
//  Created by Emirhan Demir on 03.08.24.
//

import Foundation
import SwiftData

// MARK: - Module Structure

/// Represents a quiz module with a unique identifier, name, and collection of questions.
/// This struct is designed to be easily encoded and decoded for data persistence.
struct Module: Identifiable, Codable {
    
    // MARK: Properties
    
    /// The unique identifier for the module. Used to distinguish each module uniquely.
    var id: String
    
    /// The name of the module. It represents the title or topic of the quiz.
    var name: String
    
    /// A list of questions contained within the module. It stores an array of `Question` structs.
    var questions: [Question]
}

// MARK: - Question Structure

/// Represents a question within a module, identifiable by a unique identifier.
/// Each question includes its text and the correct answer, facilitating easy quiz generation and scoring.
struct Question: Identifiable, Codable {
    
    // MARK: Properties
    
    /// The unique identifier for the question. This is crucial for tracking individual questions.
    var id: String
    
    /// The text of the question. This is the content of the quiz question presented to the user.
    var questionText: String
    
    /// The answer to the question. Stored as a string, it contains the correct answer for validation purposes.
    var answer: String
}
