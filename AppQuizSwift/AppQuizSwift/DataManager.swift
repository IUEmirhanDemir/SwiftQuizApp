//
//  DataManager.swift
//  AppQuizSwift
//
//  Created by Emirhan Demir on 01.08.24.
//

import Foundation

/// `DataManager` handles all data persistence operations for the AppQuizSwift application. It is responsible for loading, saving, and managing quiz modules and questions.
class DataManager {
    /// Shared singleton instance for global access.
    static let shared = DataManager()
    
    /// The filename for storing module data.
    private let fileName = "data.json"
    
    /// Initializes a new DataManager instance. This method also ensures initial data is copied from the bundle if necessary.
    private init() {
        createInitialDataIfNeeded()
    }
    
    /// Checks and copies initial data from the bundle to the documents directory if it does not already exist.
    private func createInitialDataIfNeeded() {
        let documentsDirectory = getDocumentsDirectory()
        let filePath = documentsDirectory.appendingPathComponent(fileName)
        
        if !FileManager.default.fileExists(atPath: filePath.path) {
            if let bundleURL = Bundle.main.url(forResource: "data", withExtension: "json") {
                do {
                    try FileManager.default.copyItem(at: bundleURL, to: filePath)
                } catch {
                    print("Error copying data file from bundle to documents directory: \(error.localizedDescription)")
                }
            } else {
                print("data.json file not found in bundle.")
            }
        }
    }
    
    /// Loads modules from the local JSON file.
    /// - Returns: An array of `Module` objects loaded from local storage.
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
    
    /// Saves modules to the local JSON file.
    /// - Parameter modules: The array of `Module` objects to be saved.
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
    
    /// Adds a new module to the existing list and saves the updated list.
    /// - Parameter newModule: The `Module` object to be added.
    func addModule(newModule: Module) {
        var modules = loadModules()
        modules.append(newModule)
        saveModules(modules: modules)
    }
    
    /// Deletes a module at specified offsets.
    /// - Parameters:
    ///   - offsets: The index set representing the positions of modules to be deleted.
    ///   - modules: The array of `Module` objects being modified.
    func deleteModule(at offsets: IndexSet, modules: inout [Module]) {
        offsets.forEach { index in
            if index < modules.count {
                modules.remove(at: index)
            }
        }
        saveModules(modules: modules)
    }
    
    /// Updates a module at a specific index with a new module.
    /// - Parameters:
    ///   - index: The index of the module to update.
    ///   - newModule: The new `Module` object that replaces the old one.
    func updateModule(at index: Int, with newModule: Module) {
        var modules = loadModules()
        if index < modules.count {
            modules[index] = newModule
            saveModules(modules: modules)
        }
    }
    
    /// Adds a new question to a specific module.
    /// - Parameters:
    ///   - moduleIndex: The index of the module to which the question is added.
    ///   - question: The `Question` object to add.
    func addQuestion(to moduleIndex: Int, question: Question) {
        var modules = loadModules()
        if moduleIndex < modules.count {
            var module = modules[moduleIndex]
            module.questions.append(question)
            modules[moduleIndex] = module
            saveModules(modules: modules)
        }
    }
    
    /// Deletes a question from a specific module.
    /// - Parameters:
    ///   - moduleIndex: The index of the module from which the question is deleted.
    ///   - questionIndex: The index of the question to delete.
    func deleteQuestion(from moduleIndex: Int, questionIndex: Int) {
        var modules = loadModules()
        if moduleIndex < modules.count {
            var module = modules[moduleIndex]
            if questionIndex < module.questions.count {
                module.questions.remove(at: questionIndex)
                modules[moduleIndex] = module
                saveModules(modules: modules)
            }
        }
    }
    
    /// Updates a specific question in a specific module.
    /// - Parameters:
    ///   - moduleIndex: The index of the module where the question is updated.
    ///   - questionIndex: The index of the question to update.
    ///   - newQuestion: The new `Question` object that replaces the old one.
    func updateQuestion(in moduleIndex: Int, at questionIndex: Int, with newQuestion: Question) {
        var modules = loadModules()
        if moduleIndex < modules.count {
            var module = modules[moduleIndex]
            if questionIndex < module.questions.count {
                module.questions[questionIndex] = newQuestion
                modules[moduleIndex] = module
                saveModules(modules: modules)
            }
        }
    }
    
    /// Retrieves the document directory path of the application.
    /// - Returns: A `URL` representing the path to the document directory.
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
