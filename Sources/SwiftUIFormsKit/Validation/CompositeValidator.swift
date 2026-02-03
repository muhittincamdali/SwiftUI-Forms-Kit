import SwiftUI
import Combine

// MARK: - Composite Validation Rule

/// A validation rule that combines multiple rules with logical operators
public struct CompositeValidationRule<Value>: ValidationRule {
    public let id = UUID()
    private let rules: [AnyValidationRule<Value>]
    private let mode: CompositionMode
    private let customMessage: String?
    
    public enum CompositionMode {
        case all       // AND - all rules must pass
        case any       // OR - at least one rule must pass
        case none      // NAND - all rules must fail
        case exactly(Int) // Exactly N rules must pass
        case atLeast(Int) // At least N rules must pass
        case atMost(Int)  // At most N rules must pass
        case range(ClosedRange<Int>) // Number of passing rules must be in range
    }
    
    public init(
        mode: CompositionMode = .all,
        message: String? = nil,
        @ValidationRuleBuilder<Value> rules: () -> [AnyValidationRule<Value>]
    ) {
        self.mode = mode
        self.customMessage = message
        self.rules = rules()
    }
    
    public func validate(_ value: Value) -> ValidationResult {
        let results = rules.map { $0.validate(value) }
        let passingCount = results.filter { $0.isValid }.count
        let totalCount = results.count
        
        let isValid: Bool
        switch mode {
        case .all:
            isValid = passingCount == totalCount
        case .any:
            isValid = passingCount > 0
        case .none:
            isValid = passingCount == 0
        case .exactly(let n):
            isValid = passingCount == n
        case .atLeast(let n):
            isValid = passingCount >= n
        case .atMost(let n):
            isValid = passingCount <= n
        case .range(let range):
            isValid = range.contains(passingCount)
        }
        
        if isValid {
            return .valid
        }
        
        // Collect error messages
        let errorMessages = results
            .filter { !$0.isValid }
            .compactMap { $0.errorMessage }
        
        let message = customMessage ?? errorMessages.first ?? "Validation failed"
        return .invalid(message: message)
    }
}

// MARK: - Validation Result

/// Result of a validation operation
public enum ValidationResult: Equatable {
    case valid
    case invalid(message: String)
    
    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
    
    public var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }
}

// MARK: - Validation Rule Protocol

/// Protocol for synchronous validation rules
public protocol ValidationRule {
    associatedtype Value
    var id: UUID { get }
    func validate(_ value: Value) -> ValidationResult
}

// MARK: - Type-Erased Validation Rule

/// Type-erased wrapper for validation rules
public struct AnyValidationRule<Value>: ValidationRule {
    public let id: UUID
    private let _validate: (Value) -> ValidationResult
    
    public init<R: ValidationRule>(_ rule: R) where R.Value == Value {
        self.id = rule.id
        self._validate = rule.validate
    }
    
    public init(
        id: UUID = UUID(),
        validate: @escaping (Value) -> ValidationResult
    ) {
        self.id = id
        self._validate = validate
    }
    
    public func validate(_ value: Value) -> ValidationResult {
        _validate(value)
    }
}

// MARK: - Result Builder for Validation Rules

@resultBuilder
public struct ValidationRuleBuilder<Value> {
    public static func buildBlock(_ rules: AnyValidationRule<Value>...) -> [AnyValidationRule<Value>] {
        rules
    }
    
    public static func buildArray(_ components: [[AnyValidationRule<Value>]]) -> [AnyValidationRule<Value>] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [AnyValidationRule<Value>]?) -> [AnyValidationRule<Value>] {
        component ?? []
    }
    
    public static func buildEither(first component: [AnyValidationRule<Value>]) -> [AnyValidationRule<Value>] {
        component
    }
    
    public static func buildEither(second component: [AnyValidationRule<Value>]) -> [AnyValidationRule<Value>] {
        component
    }
    
    public static func buildExpression(_ expression: AnyValidationRule<Value>) -> [AnyValidationRule<Value>] {
        [expression]
    }
}

// MARK: - Built-in Validation Rules

/// Validates that a string is not empty
public struct RequiredRule: ValidationRule {
    public let id = UUID()
    private let message: String
    
    public init(message: String = "This field is required") {
        self.message = message
    }
    
    public func validate(_ value: String) -> ValidationResult {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .invalid(message: message)
            : .valid
    }
}

/// Validates string minimum length
public struct MinLengthRule: ValidationRule {
    public let id = UUID()
    private let minLength: Int
    private let message: String
    
    public init(length: Int, message: String? = nil) {
        self.minLength = length
        self.message = message ?? "Must be at least \(length) characters"
    }
    
    public func validate(_ value: String) -> ValidationResult {
        value.count >= minLength ? .valid : .invalid(message: message)
    }
}

/// Validates string maximum length
public struct MaxLengthRule: ValidationRule {
    public let id = UUID()
    private let maxLength: Int
    private let message: String
    
    public init(length: Int, message: String? = nil) {
        self.maxLength = length
        self.message = message ?? "Must not exceed \(length) characters"
    }
    
    public func validate(_ value: String) -> ValidationResult {
        value.count <= maxLength ? .valid : .invalid(message: message)
    }
}

/// Validates string length within a range
public struct LengthRangeRule: ValidationRule {
    public let id = UUID()
    private let range: ClosedRange<Int>
    private let message: String
    
    public init(range: ClosedRange<Int>, message: String? = nil) {
        self.range = range
        self.message = message ?? "Must be between \(range.lowerBound) and \(range.upperBound) characters"
    }
    
    public func validate(_ value: String) -> ValidationResult {
        range.contains(value.count) ? .valid : .invalid(message: message)
    }
}

/// Validates string matches a regex pattern
public struct PatternRule: ValidationRule {
    public let id = UUID()
    private let pattern: String
    private let message: String
    
    public init(pattern: String, message: String = "Invalid format") {
        self.pattern = pattern
        self.message = message
    }
    
    public func validate(_ value: String) -> ValidationResult {
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: value) ? .valid : .invalid(message: message)
    }
}

/// Validates email format
public struct EmailRule: ValidationRule {
    public let id = UUID()
    private let message: String
    
    public init(message: String = "Please enter a valid email address") {
        self.message = message
    }
    
    public func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: value) ? .valid : .invalid(message: message)
    }
}

/// Validates URL format
public struct URLRule: ValidationRule {
    public let id = UUID()
    private let message: String
    private let requireHTTPS: Bool
    
    public init(requireHTTPS: Bool = false, message: String = "Please enter a valid URL") {
        self.requireHTTPS = requireHTTPS
        self.message = message
    }
    
    public func validate(_ value: String) -> ValidationResult {
        guard !value.isEmpty else { return .valid }
        
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              url.host != nil else {
            return .invalid(message: message)
        }
        
        if requireHTTPS && scheme != "https" {
            return .invalid(message: "URL must use HTTPS")
        }
        
        return .valid
    }
}

/// Validates numeric range
public struct NumericRangeRule<T: Comparable & Numeric>: ValidationRule {
    public let id = UUID()
    private let range: ClosedRange<T>
    private let message: String
    
    public init(range: ClosedRange<T>, message: String? = nil) {
        self.range = range
        self.message = message ?? "Value must be between \(range.lowerBound) and \(range.upperBound)"
    }
    
    public func validate(_ value: T) -> ValidationResult {
        range.contains(value) ? .valid : .invalid(message: message)
    }
}

/// Validates that a value equals another
public struct EqualsRule<T: Equatable>: ValidationRule {
    public let id = UUID()
    private let expected: T
    private let message: String
    
    public init(expected: T, message: String = "Values do not match") {
        self.expected = expected
        self.message = message
    }
    
    public func validate(_ value: T) -> ValidationResult {
        value == expected ? .valid : .invalid(message: message)
    }
}

/// Validates that a value is in a collection
public struct ContainsRule<T: Equatable>: ValidationRule {
    public let id = UUID()
    private let collection: [T]
    private let message: String
    
    public init(in collection: [T], message: String = "Invalid selection") {
        self.collection = collection
        self.message = message
    }
    
    public func validate(_ value: T) -> ValidationResult {
        collection.contains(value) ? .valid : .invalid(message: message)
    }
}

/// Custom validation rule with closure
public struct CustomRule<Value>: ValidationRule {
    public let id = UUID()
    private let validator: (Value) -> Bool
    private let message: String
    
    public init(message: String, validator: @escaping (Value) -> Bool) {
        self.message = message
        self.validator = validator
    }
    
    public func validate(_ value: Value) -> ValidationResult {
        validator(value) ? .valid : .invalid(message: message)
    }
}

// MARK: - Conditional Validation Rule

/// A validation rule that only applies when a condition is met
public struct ConditionalRule<Value>: ValidationRule {
    public let id = UUID()
    private let condition: (Value) -> Bool
    private let rule: AnyValidationRule<Value>
    
    public init(
        when condition: @escaping (Value) -> Bool,
        then rule: AnyValidationRule<Value>
    ) {
        self.condition = condition
        self.rule = rule
    }
    
    public func validate(_ value: Value) -> ValidationResult {
        guard condition(value) else { return .valid }
        return rule.validate(value)
    }
}

// MARK: - Dependent Validation Rule

/// A validation rule that depends on another field's value
public struct DependentRule<Value, DependencyValue>: ValidationRule {
    public let id = UUID()
    private let dependency: () -> DependencyValue
    private let validator: (Value, DependencyValue) -> ValidationResult
    
    public init(
        dependency: @escaping () -> DependencyValue,
        validator: @escaping (Value, DependencyValue) -> ValidationResult
    ) {
        self.dependency = dependency
        self.validator = validator
    }
    
    public func validate(_ value: Value) -> ValidationResult {
        validator(value, dependency())
    }
}

// MARK: - Validation State

/// Observable validation state for form fields
@MainActor
public class FormValidationState: ObservableObject {
    @Published public private(set) var fieldErrors: [String: String] = [:]
    @Published public private(set) var isValid = true
    @Published public private(set) var isDirty = false
    
    private var fieldRules: [String: [AnyValidationRule<String>]] = [:]
    private var fieldValues: [String: String] = [:]
    
    public init() {}
    
    /// Registers validation rules for a field
    public func register(
        field: String,
        @ValidationRuleBuilder<String> rules: () -> [AnyValidationRule<String>]
    ) {
        fieldRules[field] = rules()
    }
    
    /// Validates a single field
    public func validate(field: String, value: String) {
        fieldValues[field] = value
        isDirty = true
        
        guard let rules = fieldRules[field] else { return }
        
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                fieldErrors[field] = result.errorMessage
                updateOverallValidity()
                return
            }
        }
        
        fieldErrors.removeValue(forKey: field)
        updateOverallValidity()
    }
    
    /// Validates all registered fields
    public func validateAll() -> Bool {
        for (field, rules) in fieldRules {
            let value = fieldValues[field] ?? ""
            for rule in rules {
                let result = rule.validate(value)
                if !result.isValid {
                    fieldErrors[field] = result.errorMessage
                    break
                }
            }
        }
        
        updateOverallValidity()
        return isValid
    }
    
    /// Clears all validation errors
    public func clearErrors() {
        fieldErrors.removeAll()
        isValid = true
    }
    
    /// Resets the validation state
    public func reset() {
        clearErrors()
        isDirty = false
        fieldValues.removeAll()
    }
    
    /// Returns the error message for a field
    public func error(for field: String) -> String? {
        fieldErrors[field]
    }
    
    /// Returns whether a field has an error
    public func hasError(for field: String) -> Bool {
        fieldErrors[field] != nil
    }
    
    private func updateOverallValidity() {
        isValid = fieldErrors.isEmpty
    }
}

// MARK: - Validation View Modifier

/// View modifier for adding validation to form fields
public struct ValidationModifier: ViewModifier {
    @ObservedObject var state: FormValidationState
    let field: String
    @Binding var value: String
    let showErrorBorder: Bool
    let showErrorMessage: Bool
    
    public init(
        state: FormValidationState,
        field: String,
        value: Binding<String>,
        showErrorBorder: Bool = true,
        showErrorMessage: Bool = true
    ) {
        self.state = state
        self.field = field
        self._value = value
        self.showErrorBorder = showErrorBorder
        self.showErrorMessage = showErrorMessage
    }
    
    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            showErrorBorder && state.hasError(for: field)
                                ? Color.red
                                : Color.clear,
                            lineWidth: 1
                        )
                )
                .onChange(of: value) { newValue in
                    state.validate(field: field, value: newValue)
                }
            
            if showErrorMessage, let error = state.error(for: field) {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

extension View {
    public func formValidation(
        _ state: FormValidationState,
        field: String,
        value: Binding<String>,
        showErrorBorder: Bool = true,
        showErrorMessage: Bool = true
    ) -> some View {
        modifier(ValidationModifier(
            state: state,
            field: field,
            value: value,
            showErrorBorder: showErrorBorder,
            showErrorMessage: showErrorMessage
        ))
    }
}

// MARK: - Field Validator Binding

/// A property wrapper that combines a value with its validation
@propertyWrapper
public struct ValidatedField<Value>: DynamicProperty {
    @State private var value: Value
    @State private var error: String?
    
    private let rules: [AnyValidationRule<Value>]
    
    public var wrappedValue: Value {
        get { value }
        nonmutating set {
            value = newValue
            validate()
        }
    }
    
    public var projectedValue: ValidatedFieldProjection<Value> {
        ValidatedFieldProjection(
            value: $value,
            error: error,
            isValid: error == nil,
            validate: validate
        )
    }
    
    public init(
        wrappedValue: Value,
        @ValidationRuleBuilder<Value> rules: () -> [AnyValidationRule<Value>]
    ) {
        self._value = State(initialValue: wrappedValue)
        self.rules = rules()
    }
    
    private func validate() {
        for rule in rules {
            let result = rule.validate(value)
            if !result.isValid {
                error = result.errorMessage
                return
            }
        }
        error = nil
    }
}

/// Projected value for ValidatedField
public struct ValidatedFieldProjection<Value> {
    public let value: Binding<Value>
    public let error: String?
    public let isValid: Bool
    public let validate: () -> Void
}

// MARK: - Convenience Extensions

extension AnyValidationRule where Value == String {
    public static func required(_ message: String = "This field is required") -> AnyValidationRule {
        AnyValidationRule(RequiredRule(message: message))
    }
    
    public static func minLength(_ length: Int, message: String? = nil) -> AnyValidationRule {
        AnyValidationRule(MinLengthRule(length: length, message: message))
    }
    
    public static func maxLength(_ length: Int, message: String? = nil) -> AnyValidationRule {
        AnyValidationRule(MaxLengthRule(length: length, message: message))
    }
    
    public static func lengthRange(_ range: ClosedRange<Int>, message: String? = nil) -> AnyValidationRule {
        AnyValidationRule(LengthRangeRule(range: range, message: message))
    }
    
    public static func pattern(_ pattern: String, message: String = "Invalid format") -> AnyValidationRule {
        AnyValidationRule(PatternRule(pattern: pattern, message: message))
    }
    
    public static func email(_ message: String = "Please enter a valid email address") -> AnyValidationRule {
        AnyValidationRule(EmailRule(message: message))
    }
    
    public static func url(requireHTTPS: Bool = false, message: String = "Please enter a valid URL") -> AnyValidationRule {
        AnyValidationRule(URLRule(requireHTTPS: requireHTTPS, message: message))
    }
    
    public static func custom(_ message: String, validator: @escaping (String) -> Bool) -> AnyValidationRule {
        AnyValidationRule(CustomRule(message: message, validator: validator))
    }
}

// MARK: - Preview

#if DEBUG
struct CompositeValidator_Previews: PreviewProvider {
    static var previews: some View {
        CompositeValidatorDemoView()
    }
}

private struct CompositeValidatorDemoView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    @StateObject private var validationState = FormValidationState()
    
    var body: some View {
        Form {
            Section("Username") {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .formValidation(validationState, field: "username", value: $username)
            }
            
            Section("Email") {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .formValidation(validationState, field: "email", value: $email)
            }
            
            Section("Password") {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .formValidation(validationState, field: "password", value: $password)
            }
            
            Section("Confirm Password") {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .formValidation(validationState, field: "confirmPassword", value: $confirmPassword)
            }
            
            Section {
                Button("Submit") {
                    if validationState.validateAll() {
                        print("Form is valid!")
                    }
                }
                .disabled(!validationState.isValid)
            }
        }
        .onAppear {
            setupValidation()
        }
    }
    
    private func setupValidation() {
        validationState.register(field: "username") {
            AnyValidationRule.required()
            AnyValidationRule.minLength(3)
            AnyValidationRule.maxLength(20)
            AnyValidationRule.pattern("^[a-zA-Z][a-zA-Z0-9_]*$", message: "Username can only contain letters, numbers, and underscores")
        }
        
        validationState.register(field: "email") {
            AnyValidationRule.required()
            AnyValidationRule.email()
        }
        
        validationState.register(field: "password") {
            AnyValidationRule.required()
            AnyValidationRule.minLength(8)
            AnyValidationRule.custom("Password must contain at least one number") { value in
                value.rangeOfCharacter(from: .decimalDigits) != nil
            }
        }
        
        validationState.register(field: "confirmPassword") {
            AnyValidationRule.required()
            AnyValidationRule(DependentRule(
                dependency: { password },
                validator: { value, expected in
                    value == expected ? .valid : .invalid(message: "Passwords do not match")
                }
            ))
        }
    }
}
#endif
