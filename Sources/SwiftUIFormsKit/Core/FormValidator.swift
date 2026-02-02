import Foundation
import Combine

// MARK: - Validation Mode

/// Determines when validation is triggered
public enum ValidationMode {
    /// Validate when field loses focus
    case onBlur
    /// Validate as the user types
    case onChange
    /// Validate only on form submission
    case onSubmit
    /// Validate after a debounce period
    case debounced(milliseconds: Int)
}

// MARK: - Validation Severity

/// The severity level of a validation result
public enum ValidationSeverity: Comparable {
    case info
    case warning
    case error
}

// MARK: - Detailed Validation Result

/// A detailed validation result with severity and metadata
public struct DetailedValidationResult {
    public let isValid: Bool
    public let message: String?
    public let severity: ValidationSeverity
    public let metadata: [String: Any]

    public static let valid = DetailedValidationResult(
        isValid: true,
        message: nil,
        severity: .info,
        metadata: [:]
    )

    public static func invalid(
        _ message: String,
        severity: ValidationSeverity = .error,
        metadata: [String: Any] = [:]
    ) -> DetailedValidationResult {
        DetailedValidationResult(
            isValid: false,
            message: message,
            severity: severity,
            metadata: metadata
        )
    }

    public static func warning(
        _ message: String,
        metadata: [String: Any] = [:]
    ) -> DetailedValidationResult {
        DetailedValidationResult(
            isValid: true,
            message: message,
            severity: .warning,
            metadata: metadata
        )
    }
}

// MARK: - Form Validator

/// The main validation engine that coordinates field validation
public final class FormValidator: ObservableObject {
    @Published public var results: [String: DetailedValidationResult] = [:]
    @Published public var isValidating: Bool = false

    private var fieldRules: [String: [ValidationRule]] = [:]
    private var fieldModes: [String: ValidationMode] = [:]
    private var debounceCancellables: [String: AnyCancellable] = [:]
    private var crossFieldRules: [(keys: [String], validate: ([String: Any?]) -> DetailedValidationResult)] = []

    public init() {}

    // MARK: - Rule Registration

    /// Register validation rules for a specific field
    public func registerRules(forField key: String, rules: [ValidationRule], mode: ValidationMode = .onBlur) {
        fieldRules[key] = rules
        fieldModes[key] = mode
    }

    /// Add a cross-field validation rule
    public func addCrossFieldRule(
        keys: [String],
        validate: @escaping ([String: Any?]) -> DetailedValidationResult
    ) {
        crossFieldRules.append((keys: keys, validate: validate))
    }

    // MARK: - Validation Execution

    /// Validate a single field with its registered rules
    @discardableResult
    public func validate(field key: String, value: Any?) -> DetailedValidationResult {
        guard let rules = fieldRules[key] else {
            let result = DetailedValidationResult.valid
            results[key] = result
            return result
        }

        for rule in rules {
            let validationResult = rule.validate(value)
            if case .invalid(let message) = validationResult {
                let detailed = DetailedValidationResult.invalid(message)
                results[key] = detailed
                return detailed
            }
        }

        let result = DetailedValidationResult.valid
        results[key] = result
        return result
    }

    /// Validate a field with debouncing based on its registered mode
    public func validateWithMode(field key: String, value: Any?, in state: FormState) {
        let mode = fieldModes[key] ?? .onBlur

        switch mode {
        case .onChange:
            validate(field: key, value: value)
        case .onBlur:
            break
        case .onSubmit:
            break
        case .debounced(let ms):
            debounceCancellables[key]?.cancel()
            debounceCancellables[key] = Just(value)
                .delay(for: .milliseconds(ms), scheduler: RunLoop.main)
                .sink { [weak self] val in
                    self?.validate(field: key, value: val)
                }
        }
    }

    /// Validate all registered fields at once
    public func validateAll(state: FormState) -> Bool {
        isValidating = true
        var allValid = true

        for (key, _) in fieldRules {
            let value = state.value(forKey: key)
            let result = validate(field: key, value: value)
            if !result.isValid {
                allValid = false
            }
        }

        validateCrossFieldRules(state: state)
        isValidating = false
        return allValid
    }

    /// Run all cross-field validation rules
    private func validateCrossFieldRules(state: FormState) {
        for rule in crossFieldRules {
            var values: [String: Any?] = [:]
            for key in rule.keys {
                values[key] = state.value(forKey: key)
            }
            let result = rule.validate(values)
            if !result.isValid {
                for key in rule.keys {
                    if results[key]?.isValid ?? true {
                        results[key] = result
                    }
                }
            }
        }
    }

    // MARK: - State Queries

    /// Check if all fields are currently valid
    public var isAllValid: Bool {
        results.values.allSatisfy { $0.isValid }
    }

    /// Get all current error messages
    public var errorMessages: [String: String] {
        var messages: [String: String] = [:]
        for (key, result) in results {
            if !result.isValid, let message = result.message {
                messages[key] = message
            }
        }
        return messages
    }

    /// Get all warnings
    public var warningMessages: [String: String] {
        var messages: [String: String] = [:]
        for (key, result) in results {
            if result.severity == .warning, let message = result.message {
                messages[key] = message
            }
        }
        return messages
    }

    /// Clear all validation results
    public func clearAll() {
        results.removeAll()
        debounceCancellables.removeAll()
    }

    /// Clear validation result for a specific field
    public func clear(field key: String) {
        results.removeValue(forKey: key)
        debounceCancellables[key]?.cancel()
        debounceCancellables.removeValue(forKey: key)
    }
}
