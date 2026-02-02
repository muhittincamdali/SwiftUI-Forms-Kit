import Foundation

// MARK: - Validation Result

/// The result of a validation check
public enum ValidationResult: Equatable {
    case valid
    case invalid(String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    public var errorMessage: String? {
        if case .invalid(let message) = self { return message }
        return nil
    }

    public static func == (lhs: ValidationResult, rhs: ValidationResult) -> Bool {
        switch (lhs, rhs) {
        case (.valid, .valid):
            return true
        case (.invalid(let a), .invalid(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Validation Rule Protocol

/// Protocol for defining custom validation rules
public protocol ValidationRuleProtocol {
    var message: String { get }
    func validate(_ value: Any?) -> ValidationResult
}

// MARK: - Validation Rule

/// A concrete validation rule with a closure-based validator
public struct ValidationRule {
    public let identifier: String
    public let message: String
    private let validator: (Any?) -> ValidationResult

    public init(
        identifier: String,
        message: String,
        validator: @escaping (Any?) -> ValidationResult
    ) {
        self.identifier = identifier
        self.message = message
        self.validator = validator
    }

    /// Create a rule from a protocol-conforming type
    public init<Rule: ValidationRuleProtocol>(rule: Rule) {
        self.identifier = String(describing: type(of: rule))
        self.message = rule.message
        self.validator = rule.validate
    }

    /// Execute validation on the provided value
    public func validate(_ value: Any?) -> ValidationResult {
        validator(value)
    }
}

// MARK: - Validation Rule Composing

extension ValidationRule {
    /// Combine two rules — both must pass
    public func and(_ other: ValidationRule) -> ValidationRule {
        ValidationRule(
            identifier: "\(identifier)_and_\(other.identifier)",
            message: message
        ) { value in
            let firstResult = self.validate(value)
            guard firstResult.isValid else { return firstResult }
            return other.validate(value)
        }
    }

    /// Combine two rules — at least one must pass
    public func or(_ other: ValidationRule) -> ValidationRule {
        ValidationRule(
            identifier: "\(identifier)_or_\(other.identifier)",
            message: message
        ) { value in
            let firstResult = self.validate(value)
            if firstResult.isValid { return .valid }
            let secondResult = other.validate(value)
            if secondResult.isValid { return .valid }
            return .invalid(self.message)
        }
    }

    /// Negate the rule
    public func negated(message: String? = nil) -> ValidationRule {
        ValidationRule(
            identifier: "not_\(identifier)",
            message: message ?? "Validation failed"
        ) { value in
            let result = self.validate(value)
            return result.isValid ? .invalid(message ?? "Validation failed") : .valid
        }
    }
}
