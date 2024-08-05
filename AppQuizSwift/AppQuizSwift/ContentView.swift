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
    @State internal var modules: [Module] = []
    @State internal var selectedIndex: Int = 0
    @State internal var isShowingAddModuleView = false
    @State internal var selectedModule: Module?
    @State internal var isEditMode: EditMode = .inactive
    
    
    @State internal var showingQuiz = false
    
    
    // MARK: - Methods
    /// Deletes a module at specified indexes.
    /// - Parameter offsets: The index set of the module to be deleted.
    func deleteModule(at offsets: IndexSet) {
        DataManager.shared.deleteModule(at: offsets, modules: &modules)
    }
    
    /// Loads all modules from persistent storage.
    func loadModules() {
        self.modules = DataManager.shared.loadModules()
    }
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedIndex) {
            NavigationStack {
                List {
                    ForEach(modules.indices, id: \.self) { index in
                        if isEditMode == .active {
                            TextField("Module Name", text: Binding(
                                get: { modules[index].name },
                                set: { newValue in
                                    modules[index].name = newValue
                                    DataManager.shared.updateModule(at: index, with: modules[index])
                                }
                            ))
                        } else {
                            NavigationLink(destination: ModulDetailView(
                                module: $modules[index],
                                onEdit: { editedModule in
                                    if let moduleIndex = modules.firstIndex(where: { $0.id == editedModule.id }) {
                                        modules[moduleIndex] = editedModule
                                        DataManager.shared.updateModule(at: moduleIndex, with: editedModule)
                                    }
                                },
                                onAddQuestion: { newQuestion in
                                    if let moduleIndex = modules.firstIndex(where: { $0.id == modules[index].id }) {
                                        DataManager.shared.addQuestion(to: moduleIndex, question: newQuestion)
                                        loadModules()
                                    }
                                }
                            )) {
                                Text(modules[index].name)
                            }
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
                Button("Start Quiz") {
                    showingQuiz = true
                }
                .fullScreenCover(isPresented: $showingQuiz) {
                    StartQuizView(showingQuiz: $showingQuiz)
                        .transition(.slide)
                }
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

// MARK: - Module Detail View

/// Represents the detail view for a specific module, allowing the user to add, edit, and delete questions.
struct ModulDetailView: View {
    
    // MARK: - Properties
    @Binding var module: Module
    var onEdit: (Module) -> Void
    var onAddQuestion: (Question) -> Void
    @State internal var isShowingAddQuestionView = false
    @State internal var isEditMode: EditMode = .inactive
    
    /// Deletes a question at specified indexes.
    /// - Parameter offsets: The index set of the question to be deleted.
    func deleteQuestion(at offsets: IndexSet) {
        module.questions.remove(atOffsets: offsets)
        onEdit(module)
    }
    // MARK: - Body
    var body: some View {
        VStack {
            List {
                ForEach(module.questions.indices, id: \.self) { index in
                    if isEditMode == .active {
                        VStack {
                            TextField("Question", text: Binding(
                                get: { module.questions[index].questionText },
                                set: { newValue in
                                    module.questions[index].questionText = newValue
                                    onEdit(module)
                                }
                            ))
                            
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.gray)
                                .padding(.vertical, 4)
                            
                            
                            TextField("Answer", text: Binding(
                                get: { module.questions[index].answer },
                                set: { newValue in
                                    module.questions[index].answer = newValue
                                    onEdit(module)
                                }
                            ))
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(module.questions[index].questionText)
                            Text(module.questions[index].answer)
                        }
                    }
                }
                .onDelete(perform: { offsets in
                    deleteQuestion(at: offsets)
                })
            }
            .navigationBarItems(trailing: EditButton())
            .environment(\.editMode, $isEditMode)
            .navigationTitle("\(module.name)")
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
                    module.questions.append(newQuestion)
                    onAddQuestion(newQuestion)
                    onEdit(module)
                })
            }
        }
    }
    
    
}

// MARK: - Add Module View

/// View for adding a new module to the list.
struct AddModuleView: View {
    
    // MARK: -  Properties
    @Environment(\.dismiss) var dismiss
    @State internal var moduleName: String = ""
    
    var onAdd: (Module) -> Void
    
    // MARK: - Body
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

// MARK: - Add Question View

/// View for adding a new question to a specific module.
struct AddQuestionView: View {
    
    // MARK: -  Properties
    
    @Environment(\.dismiss) var dismiss
    @State internal var questionText: String = ""
    @State internal var answer: String = ""
    
    var onAdd: (Question) -> Void
    
    // MARK: - Body
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




// MARK: - Start Quiz View


/// `StartQuizView` - A view that manages the entire quiz lifecycle from starting a quiz, answering questions,
/// and viewing results. This view uses state management to handle user interactions and updates to the quiz state.
struct StartQuizView: View {
    
    // MARK: - State Variables
    
    /// Holds an array of quiz modules loaded from a data source.
    @State internal var modules: [Module] = []
    
    /// The currently selected quiz module.
    @State internal var selectedModule: Module?
    
    /// Current index of the question being displayed to the user.
    @State internal var currentQuestionIndex = 0
    
    /// Indicates whether the results of the quiz are currently being shown.
    @State internal var isShowingResult = false
    
    /// Total number of correct answers provided by the user.
    @State internal var numCorrectAnswers = 0
    
    /// Total number of incorrect answers provided by the user.
    @State internal var numWrongAnswers = 0
    
    /// Tracks the user's selected answer to determine feedback.
    @State internal var selectedAnswer = ""
    
    /// Controls the visibility of the feedback based on the user's answer.
    @State internal var showAnswerFeedback = false
    
    /// Holds the name of the system image that represents feedback for the last answer (correct or incorrect).
    @State internal var feedbackIconName = ""
    
    ///State to show Feedback
    @State private var showCorrectAnswer = false
    
    /// Boolean flag to indicate if the last given answer was correct.
    @State internal var lastAnswerCorrect: Bool = false
    
    /// Binding to control the display of this quiz view from a parent view.
    @Binding var showingQuiz: Bool
    
 
    
    
    // MARK: - View Body
    
    /// The body of the `StartQuizView`, which defines the user interface elements and their layout.
    var body: some View {
        VStack{
            /// Button to allow the user to exit the quiz.
            Button(action: {
                showingQuiz = false
            }, label: {
                Text("Quit Quiz")
            })
            
            .padding(.top, 5)
            
            NavigationView {
                VStack {
                    if let module = selectedModule, !isShowingResult {
                        Text(module.questions[currentQuestionIndex].questionText)
                            .transition(.slide)
                            .padding()
                            .opacity(showCorrectAnswer ? 0: 1)
                            .transition(.opacity)
                        
                        /// Displays buttons for each possible answer.
                        ForEach(currentAnswers, id: \.self) { answer in
                            Button(answer) {
                                processAnswer(answer, for: module)
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .cornerRadius(10)
                            .transition(.opacity)
                            .opacity(showCorrectAnswer ? 0 : 1)
                            
                        }
                        .transition(.opacity)

                        
                        if showCorrectAnswer, let module = selectedModule {
                            
                            VStack{
                                
                                Text("\(module.questions[currentQuestionIndex].questionText)")
                                    .font(.system(size: 24, weight: .bold))
                                    .padding(.bottom)
                                    .transition(.opacity)
                                
                                Text("Correct Answer is")
                                    .font(.system(size: 18, weight: .bold))
                                    .padding(.bottom)
                                    .transition(.opacity)

                                Text("\(module.questions[currentQuestionIndex].answer)")
                                    .foregroundColor(.green)
                                    .font(.system(size: 32, weight: .bold))
                                    .padding(.bottom)
                                    .transition(.opacity)
                            }
                            
                        }
                        
                        
                        /// Shows an image indicating whether the last answer was correct or incorrect.
                        if showAnswerFeedback {
                            Image(systemName: feedbackIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .transition(.opacity)
                                .foregroundColor(lastAnswerCorrect ? Color.green : Color.red)
                            
                        }
                    } else if isShowingResult {
                        /// Displays the quiz results with options to restart.
                        VStack {
                            Text("Quiz Completed!")
                            Text("Correct Answers: \(numCorrectAnswers) out of \(selectedModule?.questions.count ?? 0)")
                            Text("Incorrect Answers: \(numWrongAnswers) out of \(selectedModule?.questions.count ?? 0)")
                            Button("Start New Quiz") {
                                resetQuiz()
                            }
                            
                            .padding()
                        }
                    } else {
                        /// List of modules for the user to select and start a quiz.
                        List(modules) { module in
                            Button(module.name) {
                                selectedModule = module
                            }
                        }
                        .onAppear {
                            loadModules()
                        }
                    }
                }
                
                .navigationTitle(selectedModule?.name ?? "Select a Module")
                .transition(.opacity)

            }
        }
    }
    
    // MARK: -  Methods
    
    /// Processes the answer provided by the user and updates the quiz state.
    ///
    /// - Parameters:
    ///   - answer: The answer selected by the user.
    ///   - module: The current quiz module.
    internal func processAnswer(_ answer: String, for module: Module) {
        if answer == module.questions[currentQuestionIndex].answer {
            numCorrectAnswers += 1
            feedbackIconName = "checkmark.circle"
            lastAnswerCorrect = true
            goToNextQuestion()
        } else {
            numWrongAnswers += 1
            feedbackIconName = "xmark.circle"
            lastAnswerCorrect = false
            showCorrectAnswer = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
                showCorrectAnswer = false
                goToNextQuestion()
            }
        }
        showAnswerFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            showAnswerFeedback = false
        }
    }
    
    
    
    
    /// Loads modules from a data source.
    internal func loadModules() {
        modules = DataManager.shared.loadModules()
    }
    
    /// Determines the current set of answers to display, ensuring that they are shuffled.
    internal var currentAnswers: [String] {
        guard let module = selectedModule else { return [] }
        let currentQuestion = module.questions[currentQuestionIndex]
        let correctAnswer = currentQuestion.answer
        let incorrectAnswers = module.questions
            .filter { $0.answer != correctAnswer }
            .map { $0.answer }
        var answers = [correctAnswer]
        if let randomIncorrectAnswer = incorrectAnswers.randomElement() {
            answers.append(randomIncorrectAnswer)
        }
        return answers.shuffled()
    }
    
    /// Advances the quiz to the next question or ends the quiz if all questions have been answered.
    internal func goToNextQuestion() {
        guard let module = selectedModule else { return }
        if currentQuestionIndex < module.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = ""
        } else {
            isShowingResult = true
        }
    }
    
    /// Resets the quiz to its initial state for a new session.
    internal func resetQuiz() {
        currentQuestionIndex = 0
        numCorrectAnswers = 0
        numWrongAnswers = 0
        isShowingResult = false
        selectedModule = nil
        selectedAnswer = ""
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}




