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

/// `StartQuizView` manages the entire quiz lifecycle including starting a quiz, answering questions,
/// and viewing results. It leverages SwiftUI's state management to handle interactions and state updates effectively.
struct StartQuizView: View {
    
    // MARK: - State Variables
    
    /// Stores an array of quiz modules loaded from a data source.
    @State internal var modules: [Module] = []
    
    /// Holds the currently selected quiz module, allowing the user to take a specific quiz.
    @State internal var selectedModule: Module?
    
    /// Tracks the current index of the question being displayed to the user.
    @State internal var currentQuestionIndex = 0
    
    /// Indicates whether the results of the quiz are being shown.
    @State internal var isShowingResult = false
    
    /// Counts the total number of correct answers provided by the user throughout the quiz.
    @State internal var numCorrectAnswers = 0
    
    /// Counts the total number of incorrect answers provided by the user throughout the quiz.
    @State internal var numWrongAnswers = 0
    
    /// Tracks the user's selected answer to determine if it's correct or incorrect.
    @State internal var selectedAnswer = ""
    
    /// Controls the visibility of the feedback provided for the user's answer.
    @State internal var showAnswerFeedback = false
    
    /// Stores the name of the system image used to represent feedback for the last answer (either correct or incorrect).
    @State internal var feedbackIconName = ""
    
    /// Indicates whether the last given answer was correct.
    @State internal var lastAnswerCorrect: Bool = false
    
    /// Binding to control the visibility of the quiz view from a parent view.
    @Binding var showingQuiz: Bool

    /// Maintains a record of each answer provided by the user for review at the end of the quiz.
    @State internal var answerRecords: [AnswerRecord] = []
    
    // MARK: - View Body
    
    /// Defines the user interface of `StartQuizView`, arranging various UI components.
    var body: some View {
        VStack {
            /// Provides a button for the user to exit the quiz at any time.
            Button(action: {
                showingQuiz = false
            }, label: {
                Text("Quit Quiz")
            })
            .foregroundColor(.red)
            .padding(.top, 5)
            
            NavigationView {
                VStack {
                    if let module = selectedModule, !isShowingResult {
                        /// Displays the current question text from the selected module.
                        Text(module.questions[currentQuestionIndex].questionText)
                            .transition(.slide)
                            .padding()
                            .opacity(showAnswerFeedback ? 0 : 1)
                            .transition(.opacity)
                        
                        
                        /// Renders buttons for each possible answer using a dynamic grid layout.
                        let columns = [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ]

                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(currentAnswers, id: \.self) { answer in
                                Button(action: {
                                    processAnswer(answer, for: module)
                                }) {
                                    Text(answer)
                                        .foregroundColor(.blue)
                                        .fontWeight(.semibold)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                }
                                .background(Color.white)
                                .cornerRadius(10)
                                .padding(5)
                                .shadow(radius: 10)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding()
                        .opacity(showAnswerFeedback ? 0 : 1)
                        .transition(.opacity)
                        

                        /// Shows an icon indicating the correctness of the last answer.
                        if showAnswerFeedback {
                            Image(systemName: feedbackIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .transition(.opacity)
                                .foregroundColor(lastAnswerCorrect ? Color.green : Color.red)
                        }
                    } else if isShowingResult {
                        /// Displays a summary of the quiz results and allows restarting the quiz.
                        VStack {
                            Text("Quiz Completed!")
                                .font(.title)
                                .padding()
                            ScrollView {
                                VStack(spacing: 10) {
                                    ForEach(answerRecords, id: \.question) { record in
                                        VStack(alignment: .leading) {
                                            Divider()
                                            Text(record.question)
                                                .foregroundColor(.black)
                                                .fontWeight(.bold)
                                                .padding(.top)
                                            HStack {
                                                Text("Your Answer:")
                                                    .fontWeight(.medium)
                                                Text("\(record.userAnswer)")
                                                    .foregroundColor(record.isCorrect ? .green : .red)
                                                    .fontWeight(.bold)
                                            }
                                            if !record.isCorrect {
                                                HStack {
                                                    Text("Correct Answer:")
                                                        .fontWeight(.medium)
                                                    Text("\(record.correctAnswer)")
                                                        .foregroundColor(.green)
                                                        .fontWeight(.bold)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            Button("Start New Quiz") {
                                resetQuiz()
                            }
                            .padding()
                        }
                    } else {
                        /// Lists available modules for the user to select and start a quiz.
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
    
    // MARK: - Methods


    /// Processes the answer selected by the user and updates the quiz state based on correctness.
    /// - Parameters:
    ///   - answer: The answer selected by the user, as a String.
    ///   - module: The current quiz module, which contains the questions and correct answers.
    /// - Returns: None. Modifies the state directly by updating `answerRecords`, `numCorrectAnswers`, `numWrongAnswers`, and `feedbackIconName`.
    internal func processAnswer(_ answer: String, for module: Module) {
        let question = module.questions[currentQuestionIndex]
        let correct = answer == question.answer
        let record = AnswerRecord(question: question.questionText, userAnswer: answer, correctAnswer: question.answer, isCorrect: correct)

        answerRecords.append(record)
        
        if correct {
            numCorrectAnswers += 1
            feedbackIconName = "checkmark.circle"
            lastAnswerCorrect = true
        } else {
            numWrongAnswers += 1
            feedbackIconName = "xmark.circle"
            lastAnswerCorrect = false
        }
        showAnswerFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showAnswerFeedback = false
            goToNextQuestion()

        }
    }

    
    
    /// Loads quiz modules from a specified data source.
    /// - Returns: None. Updates the `modules` state variable with loaded data.
    internal func loadModules() {
        modules = DataManager.shared.loadModules()
    }
    
    
    
    /// Determines and shuffles the current set of answers to be displayed based on the current question.
    /// - Returns: An array of strings representing the shuffled answers for the current question.
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
    
    
    // Advances the quiz to the next question or concludes the quiz if all questions have been answered.
    /// - Returns: None. Updates `currentQuestionIndex` or `isShowingResult` based on the progress of the quiz.
    internal func goToNextQuestion() {
        guard let module = selectedModule else { return }
        if currentQuestionIndex < module.questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = ""
        } else {
            isShowingResult = true
        }
    }
    
    /// Resets the quiz to its initial state for a new attempt.
    /// - Returns: None. Resets all related state variables to their initial values, preparing the quiz for a new run.
    internal func resetQuiz() {
        currentQuestionIndex = 0
        numCorrectAnswers = 0
        numWrongAnswers = 0
        isShowingResult = false
        selectedModule = nil
        selectedAnswer = ""
        answerRecords = []
    }

}


/// Represents a record of an answer given by the user, detailing the question, the user's response, the correct answer, and correctness.
struct AnswerRecord {
    /// The text of the question that was answered.
    let question: String
    /// The user's response to the question.
    let userAnswer: String
    /// The correct answer to the question.
    let correctAnswer: String
    /// A Boolean value indicating whether the user's answer was correct.
    let isCorrect: Bool
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}




