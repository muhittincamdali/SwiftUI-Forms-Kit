# SwiftUI-Forms-Kit

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

A powerful, declarative form builder for SwiftUI with built-in validation, multi-step forms, and a rich set of specialized input fields.

---

## ✨ Features

- **Declarative Form Builder** — Build complex forms using `@resultBuilder` syntax
- **Real-time Validation** — Validate fields as users type with customizable rules
- **Multi-Step Forms** — Create wizard-style forms with progress tracking
- **15+ Field Types** — Text, secure, date, picker, photo, signature, credit card, OTP, and more
- **Theming System** — Consistent styling across all form elements
- **Accessibility** — Full VoiceOver and Dynamic Type support
- **Zero Dependencies** — Pure SwiftUI, no third-party libraries

---

## 📦 Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Forms-Kit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and paste:
```
https://github.com/muhittincamdali/SwiftUI-Forms-Kit.git
```

---

## 🚀 Quick Start

### Basic Form

```swift
import SwiftUIFormsKit

struct LoginForm: View {
    @StateObject private var state = FormState()

    var body: some View {
        FormBuilder(state: state) {
            FormTextField(
                key: "email",
                title: "Email",
                placeholder: "Enter your email",
                rules: [.required(), .email()]
            )

            FormSecureField(
                key: "password",
                title: "Password",
                placeholder: "Enter your password",
                rules: [.required(), .minLength(8)]
            )
        }
        .onSubmit {
            let values = state.allValues
            print("Form submitted: \(values)")
        }
    }
}
```

### Multi-Step Registration

```swift
struct RegistrationForm: View {
    @StateObject private var state = FormState()

    var body: some View {
        MultiStepForm(state: state) {
            FormStep(title: "Personal Info") {
                FormTextField(key: "name", title: "Full Name", rules: [.required()])
                FormDatePicker(key: "birthday", title: "Date of Birth")
            }

            FormStep(title: "Contact") {
                FormTextField(key: "email", title: "Email", rules: [.required(), .email()])
                FormTextField(key: "phone", title: "Phone", rules: [.phone()])
            }

            FormStep(title: "Security") {
                FormSecureField(key: "password", title: "Password", rules: [.required(), .minLength(8)])
                FormOTPField(key: "otp", title: "Verification Code", digitCount: 6)
            }
        }
    }
}
```

---

## 🧩 Available Fields

| Field | Description |
|-------|-------------|
| `FormTextField` | Standard text input with validation |
| `FormSecureField` | Password input with visibility toggle |
| `FormDatePicker` | Date selection with range constraints |
| `FormPicker` | Dropdown/wheel picker for options |
| `FormPhotoPicker` | Photo selection from library or camera |
| `FormSignatureField` | Freehand signature drawing canvas |
| `FormCreditCardField` | Credit card input with Luhn validation |
| `FormOTPField` | One-time password input with auto-advance |

---

## ✅ Validation Rules

### Built-in Rules

```swift
// Required field
.required(message: "This field is required")

// Email validation
.email(message: "Please enter a valid email")

// Phone number
.phone(message: "Invalid phone number")

// String length
.minLength(8, message: "Must be at least 8 characters")
.maxLength(100, message: "Must be at most 100 characters")

// Numeric range
.min(0, message: "Must be at least 0")
.max(999, message: "Must be at most 999")

// Pattern matching
.pattern("[A-Z]{2}[0-9]{4}", message: "Invalid format")

// Custom validation
.custom { value in
    guard let str = value as? String else { return .invalid("Invalid") }
    return str.count > 3 ? .valid : .invalid("Too short")
}
```

### Custom Validation Rules

```swift
struct PasswordStrengthRule: ValidationRuleProtocol {
    var message: String = "Password is too weak"

    func validate(_ value: Any?) -> ValidationResult {
        guard let password = value as? String else {
            return .invalid(message)
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = password.range(of: "[!@#$%^&*]", options: .regularExpression) != nil

        let strength = [hasUppercase, hasLowercase, hasNumber, hasSpecial].filter { $0 }.count
        return strength >= 3 ? .valid : .invalid(message)
    }
}
```

---

## 🎨 Theming

```swift
let customTheme = FormTheme(
    primaryColor: .blue,
    errorColor: .red,
    backgroundColor: .gray.opacity(0.1),
    cornerRadius: 12,
    fieldSpacing: 16,
    labelFont: .headline,
    inputFont: .body,
    errorFont: .caption
)

FormBuilder(state: state, theme: customTheme) {
    // your fields
}
```

---

## 📐 Architecture

```
SwiftUIFormsKit/
├── Core/
│   ├── FormBuilder.swift        # @resultBuilder for declarative forms
│   ├── FormState.swift          # Observable form state management
│   └── FormValidator.swift      # Validation engine
├── Validation/
│   ├── ValidationRule.swift     # Rule protocol & result types
│   └── BuiltInRules.swift       # Required, email, phone, min, max
├── Fields/
│   ├── FormTextField.swift      # Text input
│   ├── FormSecureField.swift    # Password input
│   ├── FormDatePicker.swift     # Date selection
│   ├── FormPicker.swift         # Option picker
│   ├── FormPhotoPicker.swift    # Photo selection
│   ├── FormSignatureField.swift # Signature canvas
│   ├── FormCreditCardField.swift# Credit card input
│   └── FormOTPField.swift       # OTP input
├── MultiStep/
│   └── MultiStepForm.swift      # Wizard-style forms
└── Styling/
    └── FormTheme.swift          # Theme configuration
```

---

## 🔧 Advanced Usage

### Form State Management

```swift
@StateObject private var state = FormState()

// Get a specific value
let email = state.value(forKey: "email") as? String

// Check if form is valid
if state.isValid {
    submitForm()
}

// Get all validation errors
let errors = state.validationErrors

// Reset form
state.reset()

// Programmatically set values
state.setValue("john@example.com", forKey: "email")
```

### Conditional Fields

```swift
FormBuilder(state: state) {
    FormPicker(key: "type", title: "Account Type", options: ["Personal", "Business"])

    if state.value(forKey: "type") as? String == "Business" {
        FormTextField(key: "company", title: "Company Name", rules: [.required()])
        FormTextField(key: "taxId", title: "Tax ID", rules: [.required()])
    }
}
```

### Credit Card with Live Formatting

```swift
FormCreditCardField(
    key: "card",
    title: "Card Number",
    showCardBrand: true,
    supportedBrands: [.visa, .mastercard, .amex]
)
```

---

## 📋 Requirements

| Platform | Minimum Version |
|----------|----------------|
| iOS      | 16.0           |
| macOS    | 13.0           |
| tvOS     | 16.0           |
| watchOS  | 9.0            |
| Swift    | 5.9            |

---

## 🗺️ Roadmap

- [ ] Form field animations
- [ ] Address auto-complete field
- [ ] File upload field
- [ ] Color picker field
- [ ] Form persistence (UserDefaults / Keychain)
- [ ] Server-side validation support
- [ ] Form analytics and tracking
- [ ] Localization support for 20+ languages

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by Formik and React Hook Form patterns
- Built with love for the SwiftUI community
