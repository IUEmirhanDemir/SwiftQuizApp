//
//  ContentView.swift
//  AppQuizSwift
//
//  Created by Emirhan Demir on 01.08.24.
//

import SwiftUI
import Foundation

/// `ContentView` manages the main interface for the quiz application, handling module and question navigation.
struct ContentView: View {
    // MARK: - State Properties
    /// The list of quiz modules.
    @State private var modules: [Module] = []
    
    /// The currently selected tab index.
    @State private var selectedIndex: Int = 0
    
    /// Flag to show or hide the module addition view.
    @State private var isShowingAddModuleView = false
    
    /// The module currently selected for detail viewing or editing.
    @State private var selectedModule: Module?
    
    /// Flag to show or hide the question addition view.
    @State private var isShowingAddQuestionView = false
    
    /// The question currently selected for detail viewing or editing.
    @State private var selectedQuestion: Question?
    
    /// Indicates whether the view is in edit mode.
    @State private var isEditMode: EditMode = .inactive

    // MARK: - Methods

    /// Deletes a module at specified index set.
    /// - Parameter offsets: The index set corresponding to the modules that should be deleted.
    func deleteModule(at offsets: IndexSet) {
        DataManager.shared.deleteModule(at: offsets, modules: &modules)
    }
    
    /// Loads the list of modules from the data manager.
    func loadModules() {
        self.modules = DataManager.shared.loadModules()
    }

    // MARK: - Body

    /// The body of the ContentView, providing the main user interface.
    var body: some View {
           TabView(selection: $selectedIndex) {
               NavigationStack {
                   List {
                       ForEach(modules) { module in
                           NavigationLink(destination: ModulDetailView(
                               module: module,
                               onEdit: { editedModule in
                                   if let index = modules.firstIndex(where: { $0.id == editedModule.id }) {
                                       modules[index] = editedModule
                                       DataManager.shared.updateModule(at: index, with: editedModule)
                                   }
                               },
                               onAddQuestion: { newQuestion in
                                   if let moduleIndex = modules.firstIndex(where: { $0.id == module.id }) {
                                       DataManager.shared.addQuestion(to: moduleIndex, question: newQuestion)
                                       loadModules()
                                   }
                               }
                           )) {
                               Text(module.name)
                           }
                         
                       }
                    .onDelete(perform: deleteModule)
                }
                .navigationBarItems(trailing: EditButton())
                .environment(\.editMode, $isEditMode)
                .navigationTitle("Modules")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isShowingAddModuleView = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddModuleView) {
                    AddModuleView(onAdd: { newModule in
                        DataManager.shared.addModule(newModule: newModule)
                        loadModules()
                    })
                }
            }
            .tabItem {
                Label("Modules", systemImage: "folder.fill")
            }
            .tag(0)

            NavigationStack {
                Text("Start Quiz")
                    .navigationTitle("Start Quiz")
            }
            .tabItem {
                Label("Start Quiz", systemImage: "flag.2.crossed.circle.fill")
            }
            .tag(1)
        }
        .onAppear(perform: loadModules)
    }
}

// MARK: - Supporting Views

/// Represents the detail view for a specific module, allowing the user to add, edit, and delete questions.
struct ModulDetailView: View {
    var module: Module
    var onEdit: (Module) -> Void
    var onAddQuestion: (Question) -> Void
    @State private var isShowingAddQuestionView = false

    var body: some View {
        VStack {
            List(module.questions.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                    Text(module.questions[index].questionText)
                        .font(.headline)
                    Text(module.questions[index].answer)
                        .font(.subheadline)
                }
            }
            .navigationTitle(module.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddQuestionView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddQuestionView) {
                AddQuestionView(onAdd: { newQuestion in
                    onAddQuestion(newQuestion)
                })
            }
        }
    }
}

/// View for adding a new module to the list.
struct AddModuleView: View {
    @Environment(\.dismiss) var dismiss
    @State private var moduleName: String = ""
    var onAdd: (Module) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Module Name", text: $moduleName)
                .navigationTitle("Add Module")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newModule = Module(id: UUID().uuidString, name: moduleName, questions: [])
                            onAdd(newModule)
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

/// View for adding a new question to a specific module.
struct AddQuestionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var questionText: String = ""
    @State private var answer: String = ""
    var onAdd: (Question) -> Void

    var body: some View {
        NavigationView {
            Form {
                TextField("Question", text: $questionText)
                TextField("Answer", text: $answer)
                .navigationTitle("Add Question")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newQuestion = Question(id: UUID().uuidString, questionText: questionText, answer: answer)
                            onAdd(newQuestion)
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

    #Preview {
        ContentView()
            .modelContainer(for: Item.self, inMemory: true)
    }




