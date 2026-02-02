import Foundation

// MARK: - Built-in Validation Rules

extension ValidationRule {

    // MARK: - Required

    /// Validates that the field is not empty or nil
    public static func required(message: String = "This field is required") -> ValidationRule {
        ValidationRule(identifier: "required", message: message) { value in
            if value == nil { return .invalid(message) }
            if let string = value as? String, string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid(message)
            }
            return .valid
        }
    }

    // MARK: - Email

    /// Validates that the value is a properly formatted email address
    public static func email(message: String = "Please enter a valid email address") -> ValidationRule {
        ValidationRule(identifier: "email", message: message) { value in
            guard let email = value as? String, !email.isEmpty else { return .valid }
            let emailPattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", emailPattern)
            return predicate.evaluate(with: email) ? .valid : .invalid(message)
        }
    }

    // MARK: - Phone

    /// Validates that the value is a properly formatted phone number
    public static func phone(message: String = "Please enter a valid phone number") -> ValidationRule {
        ValidationRule(identifier: "phone", message: message) { value in
            guard let phone = value as? String, !phone.isEmpty else { return .valid }
            let stripped = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            guard stripped.count >= 7, stripped.count <= 15 else {
                return .invalid(message)
            }
            let phonePattern = "^[+]?[0-9\\s\\-()]{7,20}$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", phonePattern)
            return predicate.evaluate(with: phone) ? .valid : .invalid(message)
        }
    }

    // MARK: - Min Length

    /// Validates that the string value has at least the specified length
    public static func minLength(_ length: Int, message: String? = nil) -> ValidationRule {
        let msg = message ?? "Must be at least \(length) characters"
        return ValidationRule(identifier: "minLength", message: msg) { value in
            guard let string = value as? String, !string.isEmpty else { return .valid }
            return string.count >= length ? .valid : .invalid(msg)
        }
    }

    // MARK: - Max Length

    /// Validates that the string value does not exceed the specified length
    public static func maxLength(_ length: Int, message: String? = nil) -> ValidationRule {
        let msg = message ?? "Must be at most \(length) characters"
        return ValidationRule(identifier: "maxLength", message: msg) { value in
            guard let string = value as? String else { return .valid }
            return string.count <= length ? .valid : .invalid(msg)
        }
    }

    // MARK: - Min Value

    /// Validates that the numeric value is at least the specified minimum
    public static func min(_ minimum: Double, message: String? = nil) -> ValidationRule {
        let msg = message ?? "Must be at least \(minimum)"
        return ValidationRule(identifier: "min", message: msg) { value in
            if let number = value as? Double {
                return number >= minimum ? .valid : .invalid(msg)
            }
            if let number = value as? Int {
                return Double(number) >= minimum ? .valid : .invalid(msg)
            }
            if let string = value as? String, let number = Double(string) {
                return number >= minimum ? .valid : .invalid(msg)
            }
            return .valid
        }
    }

    // MARK: - Max Value

    /// Validates that the numeric value does not exceed the specified maximum
    public static func max(_ maximum: Double, message: String? = nil) -> ValidationRule {
        let msg = message ?? "Must be at most \(maximum)"
        return ValidationRule(identifier: "max", message: msg) { value in
            if let number = value as? Double {
                return number <= maximum ? .valid : .invalid(msg)
            }
            if let number = value as? Int {
                return Double(number) <= maximum ? .valid : .invalid(msg)
            }
            if let string = value as? String, let number = Double(string) {
                return number <= maximum ? .valid : .invalid(msg)
            }
            return .valid
        }
    }

    // MARK: - Pattern

    /// Validates that the value matches the specified regular expression pattern
    public static func pattern(_ regex: String, message: String = "Invalid format") -> ValidationRule {
        ValidationRule(identifier: "pattern", message: message) { value in
            guard let string = value as? String, !string.isEmpty else { return .valid }
            let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
            return predicate.evaluate(with: string) ? .valid : .invalid(message)
        }
    }

    // MARK: - Custom

    /// Create a custom validation rule with a closure
    public static func custom(
        identifier: String = "custom",
        message: String = "Validation failed",
        validator: @escaping (Any?) -> ValidationResult
    ) -> ValidationRule {
        ValidationRule(identifier: identifier, message: message, validator: validator)
    }

    // MARK: - URL

    /// Validates that the value is a properly formatted URL
    public static func url(message: String = "Please enter a valid URL") -> ValidationRule {
        ValidationRule(identifier: "url", message: message) { value in
            guard let string = value as? String, !string.isEmpty else { return .valid }
            guard URL(string: string) != nil else { return .invalid(message) }
            let urlPattern = "^https?://[^\\s/$.?#].[^\\s]*$"
            let predicate = NSPredicate(format: "SELF MATCHES %@", urlPattern)
            return predicate.evaluate(with: string) ? .valid : .invalid(message)
        }
    }

    // MARK: - Numeric

    /// Validates that the value contains only numeric characters
    public static func numeric(message: String = "Must contain only numbers") -> ValidationRule {
        ValidationRule(identifier: "numeric", message: message) { value in
            guard let string = value as? String, !string.isEmpty else { return .valid }
            return string.allSatisfy { $0.isNumber } ? .valid : .invalid(message)
        }
    }
}
