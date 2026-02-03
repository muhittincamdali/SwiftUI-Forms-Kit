import SwiftUI
import Combine

// MARK: - Form Wizard Configuration

/// Configuration for form wizard behavior and appearance
public struct FormWizardConfiguration {
    public var allowBackNavigation: Bool
    public var allowStepSkipping: Bool
    public var validateOnStepChange: Bool
    public var showProgressIndicator: Bool
    public var animationStyle: WizardAnimationStyle
    public var navigationStyle: WizardNavigationStyle
    public var completionBehavior: CompletionBehavior
    
    public init(
        allowBackNavigation: Bool = true,
        allowStepSkipping: Bool = false,
        validateOnStepChange: Bool = true,
        showProgressIndicator: Bool = true,
        animationStyle: WizardAnimationStyle = .slide,
        navigationStyle: WizardNavigationStyle = .buttons,
        completionBehavior: CompletionBehavior = .showCompletion
    ) {
        self.allowBackNavigation = allowBackNavigation
        self.allowStepSkipping = allowStepSkipping
        self.validateOnStepChange = validateOnStepChange
        self.showProgressIndicator = showProgressIndicator
        self.animationStyle = animationStyle
        self.navigationStyle = navigationStyle
        self.completionBehavior = completionBehavior
    }
    
    public static let `default` = FormWizardConfiguration()
    public static let strict = FormWizardConfiguration(
        allowBackNavigation: false,
        allowStepSkipping: false,
        validateOnStepChange: true
    )
    public static let flexible = FormWizardConfiguration(
        allowBackNavigation: true,
        allowStepSkipping: true,
        validateOnStepChange: false
    )
}

/// Animation style for step transitions
public enum WizardAnimationStyle {
    case none
    case slide
    case fade
    case scale
    case custom(AnyTransition)
    
    var transition: AnyTransition {
        switch self {
        case .none:
            return .identity
        case .slide:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .fade:
            return .opacity
        case .scale:
            return .scale.combined(with: .opacity)
        case .custom(let transition):
            return transition
        }
    }
    
    var reverseTransition: AnyTransition {
        switch self {
        case .none:
            return .identity
        case .slide:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        case .fade:
            return .opacity
        case .scale:
            return .scale.combined(with: .opacity)
        case .custom(let transition):
            return transition
        }
    }
}

/// Navigation style for the wizard
public enum WizardNavigationStyle {
    case buttons          // Next/Back buttons
    case swipe            // Swipe gestures
    case both             // Buttons and swipe
    case custom           // Custom navigation
}

/// Behavior when wizard is completed
public enum CompletionBehavior {
    case showCompletion   // Show completion view
    case autoSubmit       // Auto-submit form
    case dismiss          // Dismiss wizard
    case custom           // Custom behavior
}

// MARK: - Wizard Step Protocol

/// Protocol for defining wizard steps
public protocol WizardStep: Identifiable {
    associatedtype Content: View
    
    var id: String { get }
    var title: String { get }
    var subtitle: String? { get }
    var icon: String { get }
    var isOptional: Bool { get }
    
    func validate() -> Bool
    
    @ViewBuilder
    var content: Content { get }
}

extension WizardStep {
    public var subtitle: String? { nil }
    public var icon: String { "circle" }
    public var isOptional: Bool { false }
    public func validate() -> Bool { true }
}

// MARK: - Wizard Step Model

/// Concrete implementation of a wizard step
public struct WizardStepModel<Content: View>: WizardStep {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let isOptional: Bool
    private let validator: () -> Bool
    private let contentBuilder: () -> Content
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        icon: String = "circle",
        isOptional: Bool = false,
        validator: @escaping () -> Bool = { true },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isOptional = isOptional
        self.validator = validator
        self.contentBuilder = content
    }
    
    public func validate() -> Bool {
        validator()
    }
    
    public var content: Content {
        contentBuilder()
    }
}

// MARK: - Type-Erased Wizard Step

/// Type-erased wrapper for wizard steps
public struct AnyWizardStep: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String
    public let isOptional: Bool
    private let _validate: () -> Bool
    private let _content: AnyView
    
    public init<S: WizardStep>(_ step: S) {
        self.id = step.id
        self.title = step.title
        self.subtitle = step.subtitle
        self.icon = step.icon
        self.isOptional = step.isOptional
        self._validate = step.validate
        self._content = AnyView(step.content)
    }
    
    public func validate() -> Bool {
        _validate()
    }
    
    public var content: AnyView {
        _content
    }
}

// MARK: - Wizard State

/// Observable state for the form wizard
@MainActor
public class FormWizardState: ObservableObject {
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var completedSteps: Set<Int> = []
    @Published public private(set) var isCompleted = false
    @Published public private(set) var isNavigating = false
    @Published public private(set) var navigationDirection: NavigationDirection = .forward
    @Published public var validationErrors: [String: String] = [:]
    
    public enum NavigationDirection {
        case forward
        case backward
    }
    
    private let steps: [AnyWizardStep]
    private let configuration: FormWizardConfiguration
    private let onComplete: (() -> Void)?
    private let onStepChange: ((Int, Int) -> Void)?
    
    public init(
        steps: [AnyWizardStep],
        configuration: FormWizardConfiguration = .default,
        onComplete: (() -> Void)? = nil,
        onStepChange: ((Int, Int) -> Void)? = nil
    ) {
        self.steps = steps
        self.configuration = configuration
        self.onComplete = onComplete
        self.onStepChange = onStepChange
    }
    
    // MARK: - Navigation
    
    public var canGoNext: Bool {
        currentStepIndex < steps.count - 1
    }
    
    public var canGoBack: Bool {
        configuration.allowBackNavigation && currentStepIndex > 0
    }
    
    public var currentStep: AnyWizardStep {
        steps[currentStepIndex]
    }
    
    public var progress: Double {
        Double(currentStepIndex + 1) / Double(steps.count)
    }
    
    public var isFirstStep: Bool {
        currentStepIndex == 0
    }
    
    public var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }
    
    public func goToNext() {
        guard canGoNext else {
            if isLastStep {
                complete()
            }
            return
        }
        
        if configuration.validateOnStepChange && !currentStep.validate() {
            return
        }
        
        let oldIndex = currentStepIndex
        completedSteps.insert(currentStepIndex)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationDirection = .forward
            currentStepIndex += 1
        }
        
        onStepChange?(oldIndex, currentStepIndex)
    }
    
    public func goToPrevious() {
        guard canGoBack else { return }
        
        let oldIndex = currentStepIndex
        
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationDirection = .backward
            currentStepIndex -= 1
        }
        
        onStepChange?(oldIndex, currentStepIndex)
    }
    
    public func goToStep(_ index: Int) {
        guard index >= 0 && index < steps.count else { return }
        
        if !configuration.allowStepSkipping && index > currentStepIndex + 1 {
            return
        }
        
        let oldIndex = currentStepIndex
        
        withAnimation(.easeInOut(duration: 0.3)) {
            navigationDirection = index > currentStepIndex ? .forward : .backward
            currentStepIndex = index
        }
        
        onStepChange?(oldIndex, currentStepIndex)
    }
    
    public func complete() {
        guard !isCompleted else { return }
        
        // Validate all required steps
        for (index, step) in steps.enumerated() {
            if !step.isOptional && !step.validate() {
                goToStep(index)
                return
            }
        }
        
        completedSteps.insert(currentStepIndex)
        isCompleted = true
        onComplete?()
    }
    
    public func reset() {
        withAnimation {
            currentStepIndex = 0
            completedSteps.removeAll()
            isCompleted = false
            validationErrors.removeAll()
            navigationDirection = .forward
        }
    }
    
    public func isStepCompleted(_ index: Int) -> Bool {
        completedSteps.contains(index)
    }
    
    public func isStepAccessible(_ index: Int) -> Bool {
        if configuration.allowStepSkipping { return true }
        return index <= currentStepIndex || completedSteps.contains(index - 1)
    }
}

// MARK: - Form Wizard View

/// A multi-step form wizard component
public struct FormWizard: View {
    @ObservedObject private var state: FormWizardState
    private let steps: [AnyWizardStep]
    private let configuration: FormWizardConfiguration
    private let headerView: AnyView?
    private let footerView: AnyView?
    private let completionView: AnyView?
    
    public init(
        state: FormWizardState,
        steps: [AnyWizardStep],
        configuration: FormWizardConfiguration = .default,
        @ViewBuilder header: () -> some View = { EmptyView() },
        @ViewBuilder footer: () -> some View = { EmptyView() },
        @ViewBuilder completion: () -> some View = { DefaultCompletionView() }
    ) {
        self.state = state
        self.steps = steps
        self.configuration = configuration
        self.headerView = AnyView(header())
        self.footerView = AnyView(footer())
        self.completionView = AnyView(completion())
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            if let headerView = headerView {
                headerView
            }
            
            // Progress indicator
            if configuration.showProgressIndicator {
                progressIndicator
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            
            // Content
            if state.isCompleted {
                completionView
                    .transition(.opacity)
            } else {
                stepContent
            }
            
            Spacer()
            
            // Navigation buttons
            if configuration.navigationStyle != .swipe && !state.isCompleted {
                navigationButtons
                    .padding()
            }
            
            // Footer
            if let footerView = footerView {
                footerView
            }
        }
        .gesture(swipeGesture)
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            // Step indicators
            HStack(spacing: 4) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    stepIndicator(for: step, at: index)
                }
            }
            
            // Progress text
            Text("Step \(state.currentStepIndex + 1) of \(steps.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func stepIndicator(for step: AnyWizardStep, at index: Int) -> some View {
        let isCompleted = state.isStepCompleted(index)
        let isCurrent = state.currentStepIndex == index
        let isAccessible = state.isStepAccessible(index)
        
        return Button {
            if isAccessible || configuration.allowStepSkipping {
                state.goToStep(index)
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(backgroundColor(for: index, isCompleted: isCompleted, isCurrent: isCurrent))
                        .frame(width: 32, height: 32)
                    
                    if isCompleted && !isCurrent {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(isCurrent || isCompleted ? .white : .secondary)
                    }
                }
                
                Text(step.title)
                    .font(.caption2)
                    .foregroundColor(isCurrent ? .primary : .secondary)
                    .lineLimit(1)
            }
        }
        .disabled(!isAccessible && !configuration.allowStepSkipping)
        .frame(maxWidth: .infinity)
    }
    
    private func backgroundColor(for index: Int, isCompleted: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return .accentColor
        } else if isCompleted {
            return .green
        } else {
            return Color(.systemGray5)
        }
    }
    
    // MARK: - Step Content
    
    private var stepContent: some View {
        Group {
            let step = state.currentStep
            
            VStack(alignment: .leading, spacing: 16) {
                // Step header
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.title)
                        .font(.title2.bold())
                    
                    if let subtitle = step.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Step content
                step.content
                    .padding(.horizontal)
            }
            .transition(state.navigationDirection == .forward
                ? configuration.animationStyle.transition
                : configuration.animationStyle.reverseTransition)
            .id(step.id)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Back button
            if state.canGoBack {
                Button {
                    state.goToPrevious()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }
            
            // Next/Complete button
            Button {
                if state.isLastStep {
                    state.complete()
                } else {
                    state.goToNext()
                }
            } label: {
                HStack {
                    Text(state.isLastStep ? "Complete" : "Next")
                    if !state.isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Swipe Gesture
    
    private var swipeGesture: some Gesture {
        guard configuration.navigationStyle == .swipe || configuration.navigationStyle == .both else {
            return DragGesture().onEnded { _ in }
        }
        
        return DragGesture(minimumDistance: 50)
            .onEnded { value in
                let horizontalAmount = value.translation.width
                let verticalAmount = value.translation.height
                
                if abs(horizontalAmount) > abs(verticalAmount) {
                    if horizontalAmount < 0 {
                        // Swipe left - next
                        state.goToNext()
                    } else {
                        // Swipe right - back
                        state.goToPrevious()
                    }
                }
            }
    }
}

// MARK: - Default Completion View

/// Default completion view shown when wizard is finished
public struct DefaultCompletionView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("All Done!")
                .font(.title.bold())
            
            Text("You have successfully completed all steps.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Wizard Step Builder

@resultBuilder
public struct WizardStepBuilder {
    public static func buildBlock(_ steps: AnyWizardStep...) -> [AnyWizardStep] {
        steps
    }
    
    public static func buildArray(_ components: [[AnyWizardStep]]) -> [AnyWizardStep] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [AnyWizardStep]?) -> [AnyWizardStep] {
        component ?? []
    }
    
    public static func buildEither(first component: [AnyWizardStep]) -> [AnyWizardStep] {
        component
    }
    
    public static func buildEither(second component: [AnyWizardStep]) -> [AnyWizardStep] {
        component
    }
    
    public static func buildExpression<S: WizardStep>(_ expression: S) -> [AnyWizardStep] {
        [AnyWizardStep(expression)]
    }
}

// MARK: - Convenience Initializer

extension FormWizard {
    public init(
        configuration: FormWizardConfiguration = .default,
        onComplete: (() -> Void)? = nil,
        onStepChange: ((Int, Int) -> Void)? = nil,
        @WizardStepBuilder steps: () -> [AnyWizardStep]
    ) {
        let stepsArray = steps()
        let state = FormWizardState(
            steps: stepsArray,
            configuration: configuration,
            onComplete: onComplete,
            onStepChange: onStepChange
        )
        self.init(
            state: state,
            steps: stepsArray,
            configuration: configuration
        )
    }
}

// MARK: - Step Convenience Functions

/// Creates a wizard step with the given configuration
public func wizardStep<Content: View>(
    id: String = UUID().uuidString,
    title: String,
    subtitle: String? = nil,
    icon: String = "circle",
    isOptional: Bool = false,
    validator: @escaping () -> Bool = { true },
    @ViewBuilder content: @escaping () -> Content
) -> AnyWizardStep {
    AnyWizardStep(WizardStepModel(
        id: id,
        title: title,
        subtitle: subtitle,
        icon: icon,
        isOptional: isOptional,
        validator: validator,
        content: content
    ))
}

// MARK: - Preview

#if DEBUG
struct FormWizard_Previews: PreviewProvider {
    static var previews: some View {
        FormWizardDemoView()
    }
}

private struct FormWizardDemoView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var agreeToTerms = false
    
    var body: some View {
        NavigationView {
            FormWizard(
                configuration: .default,
                onComplete: {
                    print("Wizard completed!")
                }
            ) {
                wizardStep(
                    title: "Personal Info",
                    subtitle: "Tell us about yourself",
                    icon: "person.fill",
                    validator: { !name.isEmpty }
                ) {
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Please enter your full legal name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                wizardStep(
                    title: "Contact",
                    subtitle: "How can we reach you?",
                    icon: "envelope.fill",
                    validator: { email.contains("@") }
                ) {
                    VStack(spacing: 16) {
                        TextField("Email Address", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                }
                
                wizardStep(
                    title: "Security",
                    subtitle: "Protect your account",
                    icon: "lock.fill",
                    validator: { password.count >= 8 }
                ) {
                    VStack(spacing: 16) {
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Password must be at least 8 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                wizardStep(
                    title: "Review",
                    subtitle: "Confirm your details",
                    icon: "checkmark.circle.fill",
                    validator: { agreeToTerms }
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        Group {
                            LabeledContent("Name", value: name)
                            LabeledContent("Email", value: email)
                            LabeledContent("Password", value: String(repeating: "•", count: password.count))
                        }
                        
                        Toggle("I agree to the Terms and Conditions", isOn: $agreeToTerms)
                    }
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
