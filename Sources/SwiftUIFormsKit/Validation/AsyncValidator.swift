import SwiftUI
import Combine

// MARK: - Async Validation Protocol

/// Protocol for asynchronous validation operations
public protocol AsyncValidatorProtocol {
    associatedtype Value
    
    /// Validates the given value asynchronously
    /// - Parameter value: The value to validate
    /// - Returns: A validation result indicating success or failure with error message
    func validate(_ value: Value) async throws -> AsyncValidationResult
    
    /// A descriptive name for this validator (for debugging and UI)
    var name: String { get }
    
    /// The priority of this validator (lower runs first)
    var priority: Int { get }
}

// MARK: - Async Validation Result

/// Represents the result of an async validation operation
public struct AsyncValidationResult: Equatable {
    public let isValid: Bool
    public let message: String?
    public let severity: ValidationSeverity
    public let metadata: [String: String]
    
    public init(
        isValid: Bool,
        message: String? = nil,
        severity: ValidationSeverity = .error,
        metadata: [String: String] = [:]
    ) {
        self.isValid = isValid
        self.message = message
        self.severity = severity
        self.metadata = metadata
    }
    
    public static let valid = AsyncValidationResult(isValid: true)
    
    public static func invalid(_ message: String, severity: ValidationSeverity = .error) -> AsyncValidationResult {
        AsyncValidationResult(isValid: false, message: message, severity: severity)
    }
    
    public static func warning(_ message: String) -> AsyncValidationResult {
        AsyncValidationResult(isValid: true, message: message, severity: .warning)
    }
}

/// Severity levels for validation messages
public enum ValidationSeverity: Int, Comparable {
    case info = 0
    case warning = 1
    case error = 2
    case critical = 3
    
    public static func < (lhs: ValidationSeverity, rhs: ValidationSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Type-Erased Async Validator

/// Type-erased wrapper for async validators
public struct AnyAsyncValidator<Value>: AsyncValidatorProtocol {
    private let _validate: (Value) async throws -> AsyncValidationResult
    public let name: String
    public let priority: Int
    
    public init<V: AsyncValidatorProtocol>(_ validator: V) where V.Value == Value {
        self._validate = validator.validate
        self.name = validator.name
        self.priority = validator.priority
    }
    
    public init(
        name: String,
        priority: Int = 0,
        validate: @escaping (Value) async throws -> AsyncValidationResult
    ) {
        self.name = name
        self.priority = priority
        self._validate = validate
    }
    
    public func validate(_ value: Value) async throws -> AsyncValidationResult {
        try await _validate(value)
    }
}

// MARK: - Async Validation State

/// Observable state for async validation
@MainActor
public class AsyncValidationState<Value>: ObservableObject {
    @Published public private(set) var isValidating = false
    @Published public private(set) var results: [String: AsyncValidationResult] = [:]
    @Published public private(set) var overallResult: AsyncValidationResult = .valid
    @Published public private(set) var lastValidatedValue: Value?
    
    private var validators: [AnyAsyncValidator<Value>] = []
    private var validationTask: Task<Void, Never>?
    private var debounceTime: TimeInterval
    private var validateOnlyOnChange: Bool
    
    public init(
        debounceTime: TimeInterval = 0.3,
        validateOnlyOnChange: Bool = true
    ) {
        self.debounceTime = debounceTime
        self.validateOnlyOnChange = validateOnlyOnChange
    }
    
    /// Adds a validator to the validation chain
    public func addValidator(_ validator: AnyAsyncValidator<Value>) {
        validators.append(validator)
        validators.sort { $0.priority < $1.priority }
    }
    
    /// Removes all validators
    public func clearValidators() {
        validators.removeAll()
        results.removeAll()
        overallResult = .valid
    }
    
    /// Validates the given value with all registered validators
    public func validate(_ value: Value, force: Bool = false) {
        validationTask?.cancel()
        
        validationTask = Task { [weak self] in
            guard let self = self else { return }
            
            // Debounce
            do {
                try await Task.sleep(nanoseconds: UInt64(debounceTime * 1_000_000_000))
            } catch {
                return
            }
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.isValidating = true
                self.results.removeAll()
            }
            
            var allResults: [String: AsyncValidationResult] = [:]
            var hasError = false
            var highestSeverity: ValidationSeverity = .info
            var errorMessage: String?
            
            for validator in validators {
                guard !Task.isCancelled else { break }
                
                do {
                    let result = try await validator.validate(value)
                    allResults[validator.name] = result
                    
                    if !result.isValid {
                        hasError = true
                        if result.severity > highestSeverity {
                            highestSeverity = result.severity
                            errorMessage = result.message
                        }
                    }
                } catch {
                    let result = AsyncValidationResult.invalid(
                        "Validation failed: \(error.localizedDescription)",
                        severity: .error
                    )
                    allResults[validator.name] = result
                    hasError = true
                }
            }
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                self.results = allResults
                self.lastValidatedValue = value
                self.overallResult = hasError
                    ? AsyncValidationResult.invalid(errorMessage ?? "Validation failed", severity: highestSeverity)
                    : .valid
                self.isValidating = false
            }
        }
    }
    
    /// Cancels any ongoing validation
    public func cancel() {
        validationTask?.cancel()
        isValidating = false
    }
    
    /// Resets all validation state
    public func reset() {
        cancel()
        results.removeAll()
        overallResult = .valid
        lastValidatedValue = nil
    }
    
    /// Returns whether the current validation state is valid
    public var isValid: Bool {
        overallResult.isValid && !isValidating
    }
    
    /// Returns all error messages from failed validations
    public var errorMessages: [String] {
        results.values
            .filter { !$0.isValid }
            .compactMap { $0.message }
    }
    
    /// Returns all warning messages
    public var warningMessages: [String] {
        results.values
            .filter { $0.isValid && $0.severity == .warning }
            .compactMap { $0.message }
    }
}

// MARK: - Built-in Async Validators

/// Async email validator that checks format and optionally domain
public struct AsyncEmailValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "Email Validator"
    public let priority: Int
    private let checkDomainExists: Bool
    
    public init(priority: Int = 0, checkDomainExists: Bool = false) {
        self.priority = priority
        self.checkDomainExists = checkDomainExists
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .valid
        }
        
        // Basic format check
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard predicate.evaluate(with: value) else {
            return .invalid("Please enter a valid email address")
        }
        
        // Optional domain check
        if checkDomainExists {
            guard let domain = value.split(separator: "@").last else {
                return .invalid("Invalid email format")
            }
            
            // Simulate DNS lookup (in real app, use actual DNS resolution)
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            let blockedDomains = ["tempmail.com", "throwaway.com", "fakeemail.com"]
            if blockedDomains.contains(String(domain)) {
                return .invalid("Temporary email addresses are not allowed")
            }
        }
        
        return .valid
    }
}

/// Async username validator with availability check
public struct AsyncUsernameValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "Username Validator"
    public let priority: Int
    private let minLength: Int
    private let maxLength: Int
    private let checkAvailability: ((String) async throws -> Bool)?
    
    public init(
        priority: Int = 0,
        minLength: Int = 3,
        maxLength: Int = 20,
        checkAvailability: ((String) async throws -> Bool)? = nil
    ) {
        self.priority = priority
        self.minLength = minLength
        self.maxLength = maxLength
        self.checkAvailability = checkAvailability
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .invalid("Username is required")
        }
        
        // Length check
        if value.count < minLength {
            return .invalid("Username must be at least \(minLength) characters")
        }
        
        if value.count > maxLength {
            return .invalid("Username cannot exceed \(maxLength) characters")
        }
        
        // Character check
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard value.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .invalid("Username can only contain letters, numbers, and underscores")
        }
        
        // First character check
        guard value.first?.isLetter == true else {
            return .invalid("Username must start with a letter")
        }
        
        // Availability check
        if let checkAvailability = checkAvailability {
            let isAvailable = try await checkAvailability(value)
            if !isAvailable {
                return .invalid("This username is already taken")
            }
        }
        
        return .valid
    }
}

/// Async password strength validator
public struct AsyncPasswordValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "Password Validator"
    public let priority: Int
    
    public struct Requirements {
        public var minLength: Int
        public var requireUppercase: Bool
        public var requireLowercase: Bool
        public var requireNumbers: Bool
        public var requireSpecialChars: Bool
        public var checkCommonPasswords: Bool
        public var minStrengthScore: Int
        
        public init(
            minLength: Int = 8,
            requireUppercase: Bool = true,
            requireLowercase: Bool = true,
            requireNumbers: Bool = true,
            requireSpecialChars: Bool = true,
            checkCommonPasswords: Bool = true,
            minStrengthScore: Int = 3
        ) {
            self.minLength = minLength
            self.requireUppercase = requireUppercase
            self.requireLowercase = requireLowercase
            self.requireNumbers = requireNumbers
            self.requireSpecialChars = requireSpecialChars
            self.checkCommonPasswords = checkCommonPasswords
            self.minStrengthScore = minStrengthScore
        }
        
        public static let standard = Requirements()
        public static let strict = Requirements(
            minLength: 12,
            minStrengthScore: 4
        )
        public static let relaxed = Requirements(
            minLength: 6,
            requireSpecialChars: false,
            minStrengthScore: 2
        )
    }
    
    private let requirements: Requirements
    
    public init(priority: Int = 0, requirements: Requirements = .standard) {
        self.priority = priority
        self.requirements = requirements
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .invalid("Password is required")
        }
        
        var score = 0
        var issues: [String] = []
        
        // Length check
        if value.count < requirements.minLength {
            issues.append("at least \(requirements.minLength) characters")
        } else {
            score += 1
            if value.count >= 12 { score += 1 }
            if value.count >= 16 { score += 1 }
        }
        
        // Uppercase check
        if requirements.requireUppercase {
            if value.rangeOfCharacter(from: .uppercaseLetters) != nil {
                score += 1
            } else {
                issues.append("at least one uppercase letter")
            }
        }
        
        // Lowercase check
        if requirements.requireLowercase {
            if value.rangeOfCharacter(from: .lowercaseLetters) != nil {
                score += 1
            } else {
                issues.append("at least one lowercase letter")
            }
        }
        
        // Number check
        if requirements.requireNumbers {
            if value.rangeOfCharacter(from: .decimalDigits) != nil {
                score += 1
            } else {
                issues.append("at least one number")
            }
        }
        
        // Special character check
        if requirements.requireSpecialChars {
            let specialChars = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?")
            if value.unicodeScalars.contains(where: { specialChars.contains($0) }) {
                score += 1
            } else {
                issues.append("at least one special character")
            }
        }
        
        // Common password check
        if requirements.checkCommonPasswords {
            let commonPasswords = [
                "password", "123456", "12345678", "qwerty", "abc123",
                "monkey", "1234567", "letmein", "trustno1", "dragon",
                "baseball", "iloveyou", "master", "sunshine", "ashley",
                "football", "shadow", "123123", "654321", "superman"
            ]
            
            if commonPasswords.contains(value.lowercased()) {
                return .invalid("This password is too common. Please choose a stronger password.")
            }
        }
        
        // Return result based on score and issues
        if !issues.isEmpty {
            return .invalid("Password must contain \(issues.joined(separator: ", "))")
        }
        
        if score < requirements.minStrengthScore {
            return .invalid("Password is too weak. Add more variety to make it stronger.")
        }
        
        // Strength indicator
        let strength: String
        switch score {
        case 0...2: strength = "Weak"
        case 3...4: strength = "Fair"
        case 5...6: strength = "Good"
        default: strength = "Strong"
        }
        
        return AsyncValidationResult(
            isValid: true,
            message: "Password strength: \(strength)",
            severity: .info,
            metadata: ["strength": strength, "score": "\(score)"]
        )
    }
}

/// Async URL validator with reachability check
public struct AsyncURLValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "URL Validator"
    public let priority: Int
    private let checkReachability: Bool
    private let allowedSchemes: Set<String>
    private let timeout: TimeInterval
    
    public init(
        priority: Int = 0,
        checkReachability: Bool = false,
        allowedSchemes: Set<String> = ["http", "https"],
        timeout: TimeInterval = 5.0
    ) {
        self.priority = priority
        self.checkReachability = checkReachability
        self.allowedSchemes = allowedSchemes
        self.timeout = timeout
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .valid
        }
        
        // Parse URL
        guard let url = URL(string: value) else {
            return .invalid("Please enter a valid URL")
        }
        
        // Scheme check
        guard let scheme = url.scheme?.lowercased(),
              allowedSchemes.contains(scheme) else {
            let schemes = allowedSchemes.joined(separator: " or ")
            return .invalid("URL must start with \(schemes)")
        }
        
        // Host check
        guard url.host != nil else {
            return .invalid("URL must have a valid domain")
        }
        
        // Reachability check
        if checkReachability {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = timeout
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    return .warning("Could not verify URL reachability")
                }
                
                if httpResponse.statusCode >= 400 {
                    return .warning("URL returned status code \(httpResponse.statusCode)")
                }
            } catch {
                return .warning("Could not reach URL: \(error.localizedDescription)")
            }
        }
        
        return .valid
    }
}

/// Async phone number validator
public struct AsyncPhoneValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "Phone Validator"
    public let priority: Int
    private let region: String
    private let validateFormat: Bool
    
    public init(
        priority: Int = 0,
        region: String = "US",
        validateFormat: Bool = true
    ) {
        self.priority = priority
        self.region = region
        self.validateFormat = validateFormat
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .valid
        }
        
        // Remove formatting characters
        let digitsOnly = value.filter { $0.isNumber }
        
        // Basic length check based on region
        let (minLength, maxLength) = phoneLengthForRegion(region)
        
        if digitsOnly.count < minLength {
            return .invalid("Phone number is too short")
        }
        
        if digitsOnly.count > maxLength {
            return .invalid("Phone number is too long")
        }
        
        // Format validation
        if validateFormat {
            let pattern = phonePatternForRegion(region)
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            
            if !predicate.evaluate(with: digitsOnly) {
                return .invalid("Please enter a valid phone number")
            }
        }
        
        return .valid
    }
    
    private func phoneLengthForRegion(_ region: String) -> (min: Int, max: Int) {
        switch region {
        case "US", "CA": return (10, 11)
        case "UK": return (10, 11)
        case "DE": return (10, 15)
        case "FR": return (10, 10)
        case "TR": return (10, 10)
        default: return (8, 15)
        }
    }
    
    private func phonePatternForRegion(_ region: String) -> String {
        switch region {
        case "US", "CA":
            return "^1?[2-9]\\d{9}$"
        case "UK":
            return "^(0|44)?[1-9]\\d{9}$"
        case "TR":
            return "^(0|90)?5\\d{9}$"
        default:
            return "^\\d{8,15}$"
        }
    }
}

/// Async credit card validator using Luhn algorithm
public struct AsyncCreditCardValidator: AsyncValidatorProtocol {
    public typealias Value = String
    
    public let name = "Credit Card Validator"
    public let priority: Int
    private let allowedTypes: Set<CardType>
    
    public enum CardType: String, CaseIterable {
        case visa = "Visa"
        case mastercard = "Mastercard"
        case amex = "American Express"
        case discover = "Discover"
        case dinersClub = "Diners Club"
        case jcb = "JCB"
        
        var prefixes: [String] {
            switch self {
            case .visa: return ["4"]
            case .mastercard: return ["51", "52", "53", "54", "55", "22", "23", "24", "25", "26", "27"]
            case .amex: return ["34", "37"]
            case .discover: return ["6011", "644", "645", "646", "647", "648", "649", "65"]
            case .dinersClub: return ["300", "301", "302", "303", "304", "305", "36", "38"]
            case .jcb: return ["35"]
            }
        }
        
        var validLengths: Set<Int> {
            switch self {
            case .visa: return [13, 16, 19]
            case .mastercard: return [16]
            case .amex: return [15]
            case .discover: return [16, 19]
            case .dinersClub: return [14, 16]
            case .jcb: return [16, 19]
            }
        }
    }
    
    public init(
        priority: Int = 0,
        allowedTypes: Set<CardType> = Set(CardType.allCases)
    ) {
        self.priority = priority
        self.allowedTypes = allowedTypes
    }
    
    public func validate(_ value: String) async throws -> AsyncValidationResult {
        guard !value.isEmpty else {
            return .valid
        }
        
        // Remove spaces and dashes
        let digitsOnly = value.filter { $0.isNumber }
        
        // Detect card type
        guard let cardType = detectCardType(digitsOnly) else {
            return .invalid("Unrecognized card type")
        }
        
        // Check if card type is allowed
        guard allowedTypes.contains(cardType) else {
            return .invalid("\(cardType.rawValue) cards are not accepted")
        }
        
        // Check length
        guard cardType.validLengths.contains(digitsOnly.count) else {
            return .invalid("Invalid card number length")
        }
        
        // Luhn algorithm check
        guard luhnCheck(digitsOnly) else {
            return .invalid("Invalid card number")
        }
        
        return AsyncValidationResult(
            isValid: true,
            message: nil,
            severity: .info,
            metadata: ["cardType": cardType.rawValue]
        )
    }
    
    private func detectCardType(_ number: String) -> CardType? {
        for type in CardType.allCases {
            for prefix in type.prefixes {
                if number.hasPrefix(prefix) {
                    return type
                }
            }
        }
        return nil
    }
    
    private func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let reversedDigits = number.reversed().map { Int(String($0)) ?? 0 }
        
        for (index, digit) in reversedDigits.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        
        return sum % 10 == 0
    }
}

// MARK: - Validation Chain

/// Combines multiple async validators into a chain
public struct AsyncValidationChain<Value>: AsyncValidatorProtocol {
    public let name: String
    public let priority: Int
    
    private let validators: [AnyAsyncValidator<Value>]
    private let stopOnFirstError: Bool
    
    public init(
        name: String = "Validation Chain",
        priority: Int = 0,
        stopOnFirstError: Bool = true,
        @AsyncValidatorBuilder<Value> validators: () -> [AnyAsyncValidator<Value>]
    ) {
        self.name = name
        self.priority = priority
        self.stopOnFirstError = stopOnFirstError
        self.validators = validators().sorted { $0.priority < $1.priority }
    }
    
    public func validate(_ value: Value) async throws -> AsyncValidationResult {
        var allMessages: [String] = []
        var highestSeverity: ValidationSeverity = .info
        
        for validator in validators {
            let result = try await validator.validate(value)
            
            if !result.isValid {
                if stopOnFirstError {
                    return result
                }
                
                if let message = result.message {
                    allMessages.append(message)
                }
                
                if result.severity > highestSeverity {
                    highestSeverity = result.severity
                }
            }
        }
        
        if !allMessages.isEmpty {
            return .invalid(allMessages.joined(separator: "\n"), severity: highestSeverity)
        }
        
        return .valid
    }
}

// MARK: - Result Builder for Validation Chain

@resultBuilder
public struct AsyncValidatorBuilder<Value> {
    public static func buildBlock(_ validators: AnyAsyncValidator<Value>...) -> [AnyAsyncValidator<Value>] {
        validators
    }
    
    public static func buildArray(_ components: [[AnyAsyncValidator<Value>]]) -> [AnyAsyncValidator<Value>] {
        components.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [AnyAsyncValidator<Value>]?) -> [AnyAsyncValidator<Value>] {
        component ?? []
    }
    
    public static func buildEither(first component: [AnyAsyncValidator<Value>]) -> [AnyAsyncValidator<Value>] {
        component
    }
    
    public static func buildEither(second component: [AnyAsyncValidator<Value>]) -> [AnyAsyncValidator<Value>] {
        component
    }
}

// MARK: - Validation State View Modifier

public struct AsyncValidationModifier<Value: Equatable>: ViewModifier {
    @ObservedObject var state: AsyncValidationState<Value>
    let value: Value
    let showIndicator: Bool
    let showMessages: Bool
    
    public init(
        state: AsyncValidationState<Value>,
        value: Value,
        showIndicator: Bool = true,
        showMessages: Bool = true
    ) {
        self.state = state
        self.value = value
        self.showIndicator = showIndicator
        self.showMessages = showMessages
    }
    
    public func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                content
                
                if showIndicator {
                    validationIndicator
                }
            }
            
            if showMessages {
                validationMessages
            }
        }
        .onChange(of: value) { newValue in
            state.validate(newValue)
        }
    }
    
    @ViewBuilder
    private var validationIndicator: some View {
        if state.isValidating {
            ProgressView()
                .scaleEffect(0.8)
        } else if !state.overallResult.isValid {
            Image(systemName: state.overallResult.severity.icon)
                .foregroundColor(state.overallResult.severity.color)
        } else if !state.results.isEmpty {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var validationMessages: some View {
        ForEach(state.errorMessages, id: \.self) { message in
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
        }
        
        ForEach(state.warningMessages, id: \.self) { message in
            Text(message)
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
}

extension View {
    public func asyncValidation<Value: Equatable>(
        _ state: AsyncValidationState<Value>,
        value: Value,
        showIndicator: Bool = true,
        showMessages: Bool = true
    ) -> some View {
        modifier(AsyncValidationModifier(
            state: state,
            value: value,
            showIndicator: showIndicator,
            showMessages: showMessages
        ))
    }
}

// MARK: - Preview

#if DEBUG
struct AsyncValidator_Previews: PreviewProvider {
    static var previews: some View {
        AsyncValidatorDemoView()
    }
}

private struct AsyncValidatorDemoView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    
    @StateObject private var emailValidation = AsyncValidationState<String>()
    @StateObject private var usernameValidation = AsyncValidationState<String>()
    @StateObject private var passwordValidation = AsyncValidationState<String>()
    
    var body: some View {
        Form {
            Section("Email") {
                TextField("Email", text: $email)
                    .asyncValidation(emailValidation, value: email)
            }
            
            Section("Username") {
                TextField("Username", text: $username)
                    .asyncValidation(usernameValidation, value: username)
            }
            
            Section("Password") {
                SecureField("Password", text: $password)
                    .asyncValidation(passwordValidation, value: password)
            }
        }
        .onAppear {
            emailValidation.addValidator(AnyAsyncValidator(AsyncEmailValidator()))
            usernameValidation.addValidator(AnyAsyncValidator(AsyncUsernameValidator()))
            passwordValidation.addValidator(AnyAsyncValidator(AsyncPasswordValidator()))
        }
    }
}
#endif
