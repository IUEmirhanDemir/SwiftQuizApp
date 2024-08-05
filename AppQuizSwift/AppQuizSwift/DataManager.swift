//
//  DataManager.swift
//  AppQuizSwift
//
//  Created by Emirhan Demir on 01.08.24.
//

import Foundation
import SwiftData


/// `DataManager` handles all data persistence operations for the quiz application. It uses a singleton pattern to ensure that there is a single, globally accessible instance of this class throughout the application.
class DataManager {
    // MARK: - Properties
    
    /// Shared instance of `DataManager`, ensuring a single point of access to the data management functions.
    static let shared = DataManager()
    
    /// Name of the file where quiz data is stored.
    private let fileName = "data"
    
    // MARK: - Initialization
    
    /// Initializes the `DataManager` singleton instance. It also checks for the initial data setup and performs first-time setup if necessary.
    private init() {
        createInitialDataIfNeeded()
    }

    // MARK: - Data Setup
    
    /// Ensures that initial data is copied from the bundle to the documents directory if it does not already exist.
    private func createInitialDataIfNeeded() {
        let documentsDirectory = getDocumentsDirectory()
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        // Check for the existence of the data file at the expected path
        if !FileManager.default.fileExists(atPath: filePath.path) {
            // Attempt to locate the data file in the app's main bundle
            if let bundleURL = Bundle.main.url(forResource: "data", withExtension: "json") {
                do {
                    // Copy the data file from the bundle to the documents directory
                    try FileManager.default.copyItem(at: bundleURL, to: filePath)
                } catch {
                    print("Error copying data file from bundle to documents directory: \(error.localizedDescription)")
                }
            } else {
                print("data.json file not found in bundle.")
            }
        }
    }
    
    // MARK: - Data Handling
    
    /// Loads modules from the local file system.
    /// - Returns: An array of `Module` objects if the data could be decoded successfully, or an empty array if an error occurs.
    func loadModules() -> [Module] {
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            print("File not found at path: \(filePath.path)")
            return []
        }
        
        do {
            let jsonData = try Data(contentsOf: filePath)
            let modules = try JSONDecoder().decode([Module].self, from: jsonData)
            return modules
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Saves modules to the local file system.
    /// - Parameter modules: An array of `Module` objects to be saved.
    func saveModules(modules: [Module]) {
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONEncoder().encode(modules)
            try data.write(to: filePath, options: .atomic)
            print("Modules saved successfully to path: \(filePath.path)")
        } catch {
            print("Failed to save data: \(error.localizedDescription)")
        }
    }
    
    /// Adds a new module to the existing list of modules and saves the updated list.
    /// - Parameter newModule: The `Module` object to be added.
    func addModule(newModule: Module) {
        var modules = loadModules()
        modules.append(newModule)
        saveModules(modules: modules)
    }
    
    /// Deletes a module at the specified index set and saves the updated list.
    /// - Parameters:
    ///   - offsets: The index set from which modules will be removed.
    ///   - modules: A reference to the module list from which deletions will be made.
    func deleteModule(at offsets: IndexSet, modules: inout [Module]) {
        offsets.forEach { index in
            if index < modules.count {
                modules.remove(at: index)
            }
        }
        saveModules(modules: modules)
    }
    
    /// Updates a specific module at the given index with new data and saves the updated list.
    /// - Parameters:
    ///   - index: The index of the module to be updated.
    ///   - newModule: The new `Module` data that will replace the existing module.
    func updateModule(at index: Int, with newModule: Module) {
        var modules = loadModules()
        if index < modules.count {
            modules[index] = newModule
            saveModules(modules: modules)
        }
    }

    /// Adds a new question to a specified module and saves the updated module data.
    /// - Parameters:
    ///   - moduleIndex: The index of the module to which the new question will be added.
    ///   - question: The `Question` object to be added.
    func addQuestion(to moduleIndex: Int, question: Question) {
        var modules = loadModules()
        if moduleIndex < modules.count {
            var module = modules[moduleIndex]
            module.questions.append(question)
            modules[moduleIndex] = module
            saveModules(modules: modules)
        }
    }
    
    /// Removes questions from a specified module using the provided index set and saves the updated data.
    /// - Parameters:
    ///   - moduleId: The ID of the module from which questions will be deleted.
    ///   - offsets: The index set indicating which questions to remove.
    func deleteQuestions(from moduleId: String, at offsets: IndexSet) {
        var modules = loadModules()
        if let moduleIndex = modules.firstIndex(where: { $0.id == moduleId }) {
            var module = modules[moduleIndex]
            module.questions.remove(atOffsets: offsets)
            modules[moduleIndex] = module
            saveModules(modules: modules)
        }
    }

    /// Updates a specific question within a module and saves the updated module data.
    /// - Parameters:
    ///   - moduleIndex: The index of the module containing the question.
    ///   - questionIndex: The index of the question to be updated.
    ///   - newQuestion: The updated `Question` data.
    func updateQuestion(in moduleIndex: Int, at questionIndex: Int, with newQuestion: Question) {
        var modules = loadModules()
        if moduleIndex < modules.count && questionIndex < modules[moduleIndex].questions.count {
            var module = modules[moduleIndex]
            module.questions[questionIndex] = newQuestion
            modules[moduleIndex] = module
            saveModules(modules: modules)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Retrieves the documents directory URL.
    /// - Returns: The URL of the documents directory.
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// Prints the content of the data file to the console for debugging purposes.
    func printFileContent() {
        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try Data(contentsOf: filePath)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("File content: \(jsonString)")
            }
        } catch {
            print("Error reading file content: \(error.localizedDescription)")
        }
    }
}
