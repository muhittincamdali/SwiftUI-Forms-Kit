import SwiftUI
import Combine

// MARK: - Field State

/// Represents the state of a single form field
public struct FieldState {
    public var value: Any?
    public var isTouched: Bool
    public var isDirty: Bool
    public var isDisabled: Bool
    public var validationResult: ValidationResult
    public var rules: [ValidationRule]

    public init(
        value: Any? = nil,
        isTouched: Bool = false,
        isDirty: Bool = false,
        isDisabled: Bool = false,
        validationResult: ValidationResult = .valid,
        rules: [ValidationRule] = []
    ) {
        self.value = value
        self.isTouched = isTouched
        self.isDirty = isDirty
        self.isDisabled = isDisabled
        self.validationResult = validationResult
        self.rules = rules
    }
}

// MARK: - Form State

/// Observable object that manages the entire form's state
public final class FormState: ObservableObject {
    @Published public var fields: [String: FieldState] = [:]
    @Published public var isSubmitting: Bool = false
    @Published public var submitCount: Int = 0

    private var cancellables = Set<AnyCancellable>()
    private var validators: [String: [ValidationRule]] = [:]

    public init() {}

    // MARK: - Value Management

    /// Retrieve the current value for a given field key
    public func value(forKey key: String) -> Any? {
        fields[key]?.value
    }

    /// Set a value for a given field key
    public func setValue(_ value: Any?, forKey key: String) {
        if fields[key] == nil {
            fields[key] = FieldState()
        }
        fields[key]?.value = value
        fields[key]?.isDirty = true

        if fields[key]?.isTouched == true {
            validateField(key)
        }
    }

    /// Get a binding for a string field value
    public func stringBinding(forKey key: String) -> Binding<String> {
        Binding<String>(
            get: { [weak self] in
                self?.value(forKey: key) as? String ?? ""
            },
            set: { [weak self] newValue in
                self?.setValue(newValue, forKey: key)
            }
        )
    }

    /// Get a binding for a date field value
    public func dateBinding(forKey key: String, default defaultDate: Date = Date()) -> Binding<Date> {
        Binding<Date>(
            get: { [weak self] in
                self?.value(forKey: key) as? Date ?? defaultDate
            },
            set: { [weak self] newValue in
                self?.setValue(newValue, forKey: key)
            }
        )
    }

    // MARK: - Registration

    /// Register a field with its validation rules
    public func registerField(_ key: String, rules: [ValidationRule] = [], defaultValue: Any? = nil) {
        if fields[key] == nil {
            fields[key] = FieldState(value: defaultValue, rules: rules)
        }
        validators[key] = rules
    }

    // MARK: - Touch Management

    /// Mark a field as touched (user interacted with it)
    public func touchField(_ key: String) {
        fields[key]?.isTouched = true
        validateField(key)
    }

    // MARK: - Validation

    /// Validate a single field by key
    @discardableResult
    public func validateField(_ key: String) -> Bool {
        guard let fieldState = fields[key] else { return true }
        let rules = validators[key] ?? fieldState.rules

        for rule in rules {
            let result = rule.validate(fieldState.value)
            if case .invalid = result {
                fields[key]?.validationResult = result
                return false
            }
        }

        fields[key]?.validationResult = .valid
        return true
    }

    /// Validate all registered fields
    public func validateAll() {
        submitCount += 1
        for key in fields.keys {
            fields[key]?.isTouched = true
            validateField(key)
        }
    }

    /// Check if the entire form is valid
    public var isValid: Bool {
        for key in fields.keys {
            if case .invalid = fields[key]?.validationResult {
                return false
            }
        }
        return true
    }

    /// Get all validation errors as a dictionary
    public var validationErrors: [String: String] {
        var errors: [String: String] = [:]
        for (key, state) in fields {
            if case .invalid(let message) = state.validationResult {
                errors[key] = message
            }
        }
        return errors
    }

    /// Get all current form values
    public var allValues: [String: Any] {
        var values: [String: Any] = [:]
        for (key, state) in fields {
            if let value = state.value {
                values[key] = value
            }
        }
        return values
    }

    // MARK: - Reset

    /// Reset the entire form to its initial state
    public func reset() {
        for key in fields.keys {
            fields[key]?.value = nil
            fields[key]?.isTouched = false
            fields[key]?.isDirty = false
            fields[key]?.validationResult = .valid
        }
        submitCount = 0
        isSubmitting = false
    }

    /// Reset a specific field
    public func resetField(_ key: String) {
        fields[key]?.value = nil
        fields[key]?.isTouched = false
        fields[key]?.isDirty = false
        fields[key]?.validationResult = .valid
    }
}
