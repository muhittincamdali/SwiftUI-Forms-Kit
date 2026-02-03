import XCTest
@testable import SwiftUIFormsKit

final class ValidationTests: XCTestCase {
    
    // MARK: - Required Rule Tests
    
    func testRequiredRuleWithEmptyString() {
        let rule = RequiredRule()
        let result = rule.validate("")
        
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testRequiredRuleWithWhitespaceOnly() {
        let rule = RequiredRule()
        let result = rule.validate("   ")
        
        XCTAssertFalse(result.isValid)
    }
    
    func testRequiredRuleWithValidString() {
        let rule = RequiredRule()
        let result = rule.validate("Hello")
        
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }
    
    func testRequiredRuleWithCustomMessage() {
        let customMessage = "This field cannot be empty"
        let rule = RequiredRule(message: customMessage)
        let result = rule.validate("")
        
        XCTAssertEqual(result.errorMessage, customMessage)
    }
    
    // MARK: - Min Length Rule Tests
    
    func testMinLengthRuleWithShortString() {
        let rule = MinLengthRule(length: 5)
        let result = rule.validate("Hi")
        
        XCTAssertFalse(result.isValid)
    }
    
    func testMinLengthRuleWithExactLength() {
        let rule = MinLengthRule(length: 5)
        let result = rule.validate("Hello")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testMinLengthRuleWithLongerString() {
        let rule = MinLengthRule(length: 5)
        let result = rule.validate("Hello World")
        
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Max Length Rule Tests
    
    func testMaxLengthRuleWithShortString() {
        let rule = MaxLengthRule(length: 10)
        let result = rule.validate("Hello")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testMaxLengthRuleWithExactLength() {
        let rule = MaxLengthRule(length: 5)
        let result = rule.validate("Hello")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testMaxLengthRuleWithLongerString() {
        let rule = MaxLengthRule(length: 5)
        let result = rule.validate("Hello World")
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Length Range Rule Tests
    
    func testLengthRangeRuleWithinRange() {
        let rule = LengthRangeRule(range: 3...10)
        let result = rule.validate("Hello")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testLengthRangeRuleBelowRange() {
        let rule = LengthRangeRule(range: 3...10)
        let result = rule.validate("Hi")
        
        XCTAssertFalse(result.isValid)
    }
    
    func testLengthRangeRuleAboveRange() {
        let rule = LengthRangeRule(range: 3...10)
        let result = rule.validate("Hello World!")
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Email Rule Tests
    
    func testEmailRuleWithValidEmail() {
        let rule = EmailRule()
        
        let validEmails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "user+tag@example.org",
            "user123@test.io"
        ]
        
        for email in validEmails {
            let result = rule.validate(email)
            XCTAssertTrue(result.isValid, "Expected \(email) to be valid")
        }
    }
    
    func testEmailRuleWithInvalidEmail() {
        let rule = EmailRule()
        
        let invalidEmails = [
            "invalid",
            "invalid@",
            "@domain.com",
            "invalid@domain",
            "invalid@.com"
        ]
        
        for email in invalidEmails {
            let result = rule.validate(email)
            XCTAssertFalse(result.isValid, "Expected \(email) to be invalid")
        }
    }
    
    func testEmailRuleWithEmptyString() {
        let rule = EmailRule()
        let result = rule.validate("")
        
        // Empty string is valid (use Required rule for checking emptiness)
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - URL Rule Tests
    
    func testURLRuleWithValidURL() {
        let rule = URLRule()
        
        let validURLs = [
            "https://example.com",
            "http://test.org/path",
            "https://sub.domain.com/page?query=1"
        ]
        
        for url in validURLs {
            let result = rule.validate(url)
            XCTAssertTrue(result.isValid, "Expected \(url) to be valid")
        }
    }
    
    func testURLRuleWithInvalidURL() {
        let rule = URLRule()
        
        let invalidURLs = [
            "not a url",
            "ftp://invalid",
            "//missing-scheme.com"
        ]
        
        for url in invalidURLs {
            let result = rule.validate(url)
            XCTAssertFalse(result.isValid, "Expected \(url) to be invalid")
        }
    }
    
    func testURLRuleWithHTTPSRequirement() {
        let rule = URLRule(requireHTTPS: true)
        
        let httpsResult = rule.validate("https://secure.com")
        XCTAssertTrue(httpsResult.isValid)
        
        let httpResult = rule.validate("http://insecure.com")
        XCTAssertFalse(httpResult.isValid)
    }
    
    // MARK: - Pattern Rule Tests
    
    func testPatternRuleWithMatchingPattern() {
        // US Phone number pattern
        let rule = PatternRule(pattern: "^\\d{3}-\\d{3}-\\d{4}$", message: "Invalid phone")
        let result = rule.validate("123-456-7890")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testPatternRuleWithNonMatchingPattern() {
        let rule = PatternRule(pattern: "^\\d{3}-\\d{3}-\\d{4}$", message: "Invalid phone")
        let result = rule.validate("1234567890")
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Numeric Range Rule Tests
    
    func testNumericRangeRuleWithinRange() {
        let rule = NumericRangeRule(range: 0...100)
        let result = rule.validate(50)
        
        XCTAssertTrue(result.isValid)
    }
    
    func testNumericRangeRuleBelowRange() {
        let rule = NumericRangeRule(range: 0...100)
        let result = rule.validate(-10)
        
        XCTAssertFalse(result.isValid)
    }
    
    func testNumericRangeRuleAboveRange() {
        let rule = NumericRangeRule(range: 0...100)
        let result = rule.validate(150)
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Equals Rule Tests
    
    func testEqualsRuleWithMatchingValues() {
        let rule = EqualsRule(expected: "password123", message: "Passwords don't match")
        let result = rule.validate("password123")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testEqualsRuleWithNonMatchingValues() {
        let rule = EqualsRule(expected: "password123", message: "Passwords don't match")
        let result = rule.validate("different")
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Passwords don't match")
    }
    
    // MARK: - Contains Rule Tests
    
    func testContainsRuleWithMatchingValue() {
        let rule = ContainsRule(in: ["apple", "banana", "orange"])
        let result = rule.validate("banana")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testContainsRuleWithNonMatchingValue() {
        let rule = ContainsRule(in: ["apple", "banana", "orange"])
        let result = rule.validate("grape")
        
        XCTAssertFalse(result.isValid)
    }
    
    // MARK: - Custom Rule Tests
    
    func testCustomRuleWithPassingCondition() {
        let rule = CustomRule<String>(message: "Must contain @") { value in
            value.contains("@")
        }
        let result = rule.validate("test@example.com")
        
        XCTAssertTrue(result.isValid)
    }
    
    func testCustomRuleWithFailingCondition() {
        let rule = CustomRule<String>(message: "Must contain @") { value in
            value.contains("@")
        }
        let result = rule.validate("invalid")
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Must contain @")
    }
    
    // MARK: - Composite Validation Tests
    
    func testCompositeValidationAllMode() {
        let composite = CompositeValidationRule<String>(mode: .all) {
            AnyValidationRule(RequiredRule())
            AnyValidationRule(MinLengthRule(length: 3))
            AnyValidationRule(MaxLengthRule(length: 10))
        }
        
        // Valid case
        let validResult = composite.validate("Hello")
        XCTAssertTrue(validResult.isValid)
        
        // Invalid - too short
        let shortResult = composite.validate("Hi")
        XCTAssertFalse(shortResult.isValid)
        
        // Invalid - too long
        let longResult = composite.validate("Hello World!")
        XCTAssertFalse(longResult.isValid)
    }
    
    func testCompositeValidationAnyMode() {
        let composite = CompositeValidationRule<String>(mode: .any) {
            AnyValidationRule(PatternRule(pattern: "^\\d+$", message: "Not a number"))
            AnyValidationRule(PatternRule(pattern: "^[a-z]+$", message: "Not lowercase"))
        }
        
        // Valid - matches first rule (numbers)
        let numberResult = composite.validate("123")
        XCTAssertTrue(numberResult.isValid)
        
        // Valid - matches second rule (lowercase)
        let lowercaseResult = composite.validate("hello")
        XCTAssertTrue(lowercaseResult.isValid)
        
        // Invalid - matches neither
        let mixedResult = composite.validate("Hello123")
        XCTAssertFalse(mixedResult.isValid)
    }
    
    // MARK: - Conditional Rule Tests
    
    func testConditionalRuleWhenConditionMet() {
        let rule = ConditionalRule<String>(
            when: { !$0.isEmpty },
            then: AnyValidationRule(EmailRule())
        )
        
        // Condition met, validation runs
        let result = rule.validate("invalid-email")
        XCTAssertFalse(result.isValid)
    }
    
    func testConditionalRuleWhenConditionNotMet() {
        let rule = ConditionalRule<String>(
            when: { !$0.isEmpty },
            then: AnyValidationRule(EmailRule())
        )
        
        // Condition not met, validation skipped
        let result = rule.validate("")
        XCTAssertTrue(result.isValid)
    }
    
    // MARK: - Validation State Tests
    
    @MainActor
    func testFormValidationState() async {
        let state = FormValidationState()
        
        state.register(field: "email") {
            AnyValidationRule.required()
            AnyValidationRule.email()
        }
        
        // Initially valid (no validation run)
        XCTAssertTrue(state.isValid)
        
        // Validate with invalid email
        state.validate(field: "email", value: "invalid")
        XCTAssertFalse(state.isValid)
        XCTAssertNotNil(state.error(for: "email"))
        
        // Validate with valid email
        state.validate(field: "email", value: "test@example.com")
        XCTAssertTrue(state.isValid)
        XCTAssertNil(state.error(for: "email"))
    }
    
    @MainActor
    func testFormValidationStateReset() async {
        let state = FormValidationState()
        
        state.register(field: "name") {
            AnyValidationRule.required()
        }
        
        state.validate(field: "name", value: "")
        XCTAssertFalse(state.isValid)
        XCTAssertTrue(state.isDirty)
        
        state.reset()
        XCTAssertTrue(state.isValid)
        XCTAssertFalse(state.isDirty)
    }
}

// MARK: - Async Validation Tests

final class AsyncValidationTests: XCTestCase {
    
    func testAsyncEmailValidator() async throws {
        let validator = AsyncEmailValidator()
        
        // Valid email
        let validResult = try await validator.validate("test@example.com")
        XCTAssertTrue(validResult.isValid)
        
        // Invalid email
        let invalidResult = try await validator.validate("invalid")
        XCTAssertFalse(invalidResult.isValid)
    }
    
    func testAsyncUsernameValidator() async throws {
        let validator = AsyncUsernameValidator(minLength: 3, maxLength: 15)
        
        // Valid username
        let validResult = try await validator.validate("johndoe")
        XCTAssertTrue(validResult.isValid)
        
        // Too short
        let shortResult = try await validator.validate("ab")
        XCTAssertFalse(shortResult.isValid)
        
        // Too long
        let longResult = try await validator.validate("verylongusername123")
        XCTAssertFalse(longResult.isValid)
        
        // Invalid characters
        let invalidResult = try await validator.validate("user@name")
        XCTAssertFalse(invalidResult.isValid)
        
        // Starts with number
        let numberStartResult = try await validator.validate("123user")
        XCTAssertFalse(numberStartResult.isValid)
    }
    
    func testAsyncPasswordValidator() async throws {
        let validator = AsyncPasswordValidator(requirements: .standard)
        
        // Strong password
        let strongResult = try await validator.validate("SecureP@ss123")
        XCTAssertTrue(strongResult.isValid)
        
        // Too short
        let shortResult = try await validator.validate("Abc1!")
        XCTAssertFalse(shortResult.isValid)
        
        // No uppercase
        let noUpperResult = try await validator.validate("password123!")
        XCTAssertFalse(noUpperResult.isValid)
        
        // No number
        let noNumberResult = try await validator.validate("Password!")
        XCTAssertFalse(noNumberResult.isValid)
    }
    
    func testAsyncURLValidator() async throws {
        let validator = AsyncURLValidator(checkReachability: false)
        
        // Valid URL
        let validResult = try await validator.validate("https://example.com")
        XCTAssertTrue(validResult.isValid)
        
        // Invalid URL
        let invalidResult = try await validator.validate("not-a-url")
        XCTAssertFalse(invalidResult.isValid)
    }
    
    func testAsyncPhoneValidator() async throws {
        let validator = AsyncPhoneValidator(region: "US")
        
        // Valid US phone
        let validResult = try await validator.validate("555-123-4567")
        XCTAssertTrue(validResult.isValid)
        
        // Too short
        let shortResult = try await validator.validate("123")
        XCTAssertFalse(shortResult.isValid)
    }
    
    func testAsyncCreditCardValidator() async throws {
        let validator = AsyncCreditCardValidator()
        
        // Valid Visa (test card)
        let visaResult = try await validator.validate("4111111111111111")
        XCTAssertTrue(visaResult.isValid)
        XCTAssertEqual(visaResult.metadata["cardType"], "Visa")
        
        // Valid Mastercard (test card)
        let mcResult = try await validator.validate("5555555555554444")
        XCTAssertTrue(mcResult.isValid)
        XCTAssertEqual(mcResult.metadata["cardType"], "Mastercard")
        
        // Invalid - bad Luhn
        let invalidResult = try await validator.validate("4111111111111112")
        XCTAssertFalse(invalidResult.isValid)
    }
    
    @MainActor
    func testAsyncValidationState() async throws {
        let state = AsyncValidationState<String>(debounceTime: 0.1)
        state.addValidator(AnyAsyncValidator(AsyncEmailValidator()))
        
        // Validate
        state.validate("test@example.com")
        
        // Wait for debounce and validation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        XCTAssertTrue(state.isValid)
    }
}

// MARK: - Address Model Tests

final class AddressTests: XCTestCase {
    
    func testPostalAddressFormattedSingleLine() {
        let address = PostalAddress(
            street1: "123 Main St",
            street2: "Apt 4",
            city: "San Francisco",
            state: "CA",
            postalCode: "94102",
            country: "United States"
        )
        
        let formatted = address.formattedSingleLine
        XCTAssertTrue(formatted.contains("123 Main St"))
        XCTAssertTrue(formatted.contains("San Francisco"))
        XCTAssertTrue(formatted.contains("CA"))
    }
    
    func testPostalAddressFormattedMultiLine() {
        let address = PostalAddress(
            street1: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94102",
            country: "United States"
        )
        
        let formatted = address.formattedMultiLine
        XCTAssertTrue(formatted.contains("\n"))
    }
    
    func testPostalAddressIsComplete() {
        let completeAddress = PostalAddress(
            street1: "123 Main St",
            city: "San Francisco",
            state: "CA",
            postalCode: "94102",
            country: "United States"
        )
        XCTAssertTrue(completeAddress.isComplete)
        
        let incompleteAddress = PostalAddress(
            street1: "123 Main St",
            city: "",
            state: "CA",
            postalCode: "94102",
            country: "United States"
        )
        XCTAssertFalse(incompleteAddress.isComplete)
    }
    
    func testPostalAddressIsEmpty() {
        let emptyAddress = PostalAddress()
        XCTAssertTrue(emptyAddress.isEmpty)
        
        let nonEmptyAddress = PostalAddress(street1: "123 Main St")
        XCTAssertFalse(nonEmptyAddress.isEmpty)
    }
    
    func testPostalAddressCoordinate() {
        let addressWithCoords = PostalAddress(
            street1: "Test",
            city: "Test",
            state: "TS",
            postalCode: "12345",
            country: "Test",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        XCTAssertNotNil(addressWithCoords.coordinate)
        XCTAssertEqual(addressWithCoords.coordinate?.latitude, 37.7749)
        
        let addressWithoutCoords = PostalAddress()
        XCTAssertNil(addressWithoutCoords.coordinate)
    }
    
    func testCountryUSStates() {
        let us = Country.commonCountries.first { $0.code == "US" }
        XCTAssertNotNil(us)
        XCTAssertFalse(us!.states.isEmpty)
        
        let california = us!.states.first { $0.abbreviation == "CA" }
        XCTAssertNotNil(california)
        XCTAssertEqual(california?.name, "California")
    }
    
    func testCountryPostalCodeValidation() {
        let us = Country.commonCountries.first { $0.code == "US" }!
        
        guard let regex = us.postalCodeRegex else {
            XCTFail("US should have postal code regex")
            return
        }
        
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        
        // Valid US postal codes
        XCTAssertTrue(predicate.evaluate(with: "94102"))
        XCTAssertTrue(predicate.evaluate(with: "94102-1234"))
        
        // Invalid US postal codes
        XCTAssertFalse(predicate.evaluate(with: "9410"))
        XCTAssertFalse(predicate.evaluate(with: "ABCDE"))
    }
}

// MARK: - Wizard State Tests

final class WizardTests: XCTestCase {
    
    @MainActor
    func testWizardStateNavigation() {
        let steps = [
            AnyWizardStep(WizardStepModel(title: "Step 1") { Text("1") }),
            AnyWizardStep(WizardStepModel(title: "Step 2") { Text("2") }),
            AnyWizardStep(WizardStepModel(title: "Step 3") { Text("3") })
        ]
        
        let state = FormWizardState(steps: steps)
        
        XCTAssertEqual(state.currentStepIndex, 0)
        XCTAssertTrue(state.isFirstStep)
        XCTAssertFalse(state.isLastStep)
        
        state.goToNext()
        XCTAssertEqual(state.currentStepIndex, 1)
        
        state.goToNext()
        XCTAssertEqual(state.currentStepIndex, 2)
        XCTAssertTrue(state.isLastStep)
        
        state.goToPrevious()
        XCTAssertEqual(state.currentStepIndex, 1)
    }
    
    @MainActor
    func testWizardStateProgress() {
        let steps = [
            AnyWizardStep(WizardStepModel(title: "Step 1") { Text("1") }),
            AnyWizardStep(WizardStepModel(title: "Step 2") { Text("2") }),
            AnyWizardStep(WizardStepModel(title: "Step 3") { Text("3") }),
            AnyWizardStep(WizardStepModel(title: "Step 4") { Text("4") })
        ]
        
        let state = FormWizardState(steps: steps)
        
        XCTAssertEqual(state.progress, 0.25) // 1/4
        
        state.goToNext()
        XCTAssertEqual(state.progress, 0.5) // 2/4
        
        state.goToNext()
        XCTAssertEqual(state.progress, 0.75) // 3/4
        
        state.goToNext()
        XCTAssertEqual(state.progress, 1.0) // 4/4
    }
    
    @MainActor
    func testWizardStateCompletion() {
        let steps = [
            AnyWizardStep(WizardStepModel(title: "Step 1") { Text("1") }),
            AnyWizardStep(WizardStepModel(title: "Step 2") { Text("2") })
        ]
        
        var completionCalled = false
        let state = FormWizardState(
            steps: steps,
            onComplete: { completionCalled = true }
        )
        
        state.goToNext()
        state.complete()
        
        XCTAssertTrue(state.isCompleted)
        XCTAssertTrue(completionCalled)
    }
    
    @MainActor
    func testWizardStateReset() {
        let steps = [
            AnyWizardStep(WizardStepModel(title: "Step 1") { Text("1") }),
            AnyWizardStep(WizardStepModel(title: "Step 2") { Text("2") })
        ]
        
        let state = FormWizardState(steps: steps)
        
        state.goToNext()
        state.complete()
        
        state.reset()
        
        XCTAssertEqual(state.currentStepIndex, 0)
        XCTAssertFalse(state.isCompleted)
        XCTAssertTrue(state.completedSteps.isEmpty)
    }
}
