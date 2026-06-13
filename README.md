<p align="center">
  <img src="https://img.shields.io/badge/Swift-6.0-FA7343?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 6.0"/>
  <img src="https://img.shields.io/badge/Platform-iOS%20|%20macOS%20|%20visionOS-007AFF?style=for-the-badge&logo=apple&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/Standard-Unified%20Core-5856D6?style=for-the-badge" alt="Standard"/>
</p>

---

> **🛡️ PART OF THE 2026 UNIFIED CORE**
> This repository is a verified component of 'The Endless March' initiative. Purified for Swift 6, zero-dependency, and engineered for maximum hardware saturation.
> 
> *Flagship Engines:* [SwiftNetwork](https://github.com/muhittincamdali/SwiftNetwork) | [SwiftAI](https://github.com/muhittincamdali/SwiftAI) | [LiquidGlassKit](https://github.com/muhittincamdali/LiquidGlassKit)

---

<p align="center">
  <img src="https://img.icons8.com/fluency/96/form.png" alt="SwiftUI Forms Kit" width="96"/>
</p>

<h1 align="center">SwiftUI Forms Kit</h1>

<p align="center">
  <strong>🏆 The most comprehensive form library for SwiftUI</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat-square" alt="Swift"/>
  <img src="https://img.shields.io/badge/iOS-16.0+-blue.svg?style=flat-square" alt="iOS"/>
  <img src="https://img.shields.io/badge/macOS-13.0+-purple.svg?style=flat-square" alt="macOS"/>
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License"/>
  <img src="https://img.shields.io/badge/SPM-Compatible-brightgreen.svg?style=flat-square" alt="SPM"/>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#field-types">Field Types</a> •
  <a href="#validation">Validation</a> •
  <a href="#advanced">Advanced</a>
</p>

---

## Why SwiftUI Forms Kit?

Building forms in SwiftUI can be tedious. You need validation, styling, accessibility, and state management - all from scratch. **SwiftUI Forms Kit** gives you everything out of the box:

| Feature | SwiftUI Forms Kit | Native SwiftUI | Other Libraries |
|---------|:-----------------:|:--------------:|:---------------:|
| 30+ Field Types | ✅ | ❌ | ⚠️ |
| Real-time Validation | ✅ | ❌ | ⚠️ |
| Async Validation | ✅ | ❌ | ❌ |
| JSON-Driven Forms | ✅ | ❌ | ❌ |
| Form Analytics | ✅ | ❌ | ❌ |
| Multi-Step Forms | ✅ | ❌ | ⚠️ |
| Form DSL | ✅ | ❌ | ❌ |
| Full Accessibility | ✅ | ⚠️ | ⚠️ |
| Theming System | ✅ | ❌ | ⚠️ |

---

## Features

### 📝 30+ Field Types

```
Text Fields       │ Selection         │ Date & Time       │ Special
─────────────────────────────────────────────────────────────────────
• Text Input      │ • Dropdown        │ • Date Picker     │ • Signature
• Email           │ • Multi-Select    │ • Time Picker     │ • OTP Input
• Password        │ • Radio Buttons   │ • Date Range      │ • Credit Card
• Phone (Intl)    │ • Checkboxes      │ • Time Range      │ • Address
• URL             │ • Toggle          │ • Duration        │ • File Upload
• Number          │ • Chips           │                   │ • Image Picker
• Currency        │ • Segmented       │                   │ • Rating
• Textarea        │                   │                   │ • Slider
```

### ✅ Powerful Validation

- **Built-in rules**: required, email, phone, minLength, maxLength, pattern
- **Custom validators**: Write your own validation logic
- **Async validation**: Check against APIs (username availability, etc.)
- **Field dependencies**: Validate based on other field values
- **Real-time feedback**: Instant error messages as users type

### 🎨 Theming & Styling

- Pre-built themes (Light, Dark, Minimal)
- Customize colors, spacing, corner radius
- Per-field style overrides
- Dark mode support

### ♿ Accessibility First

- Full VoiceOver support
- Dynamic Type support
- Reduce Motion support
- Screen reader announcements

---

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/muhittincamdali/SwiftUI-Forms-Kit.git", from: "2.0.0")
]
```

### CocoaPods

```ruby
pod 'SwiftUIFormsKit', '~> 2.0'
```

---

## Quick Start

### Basic Form

```swift
import SwiftUIFormsKit

struct LoginForm: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        FormContainer(title: "Sign In") {
            FormTextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .validation(.required, .email)
            
            FormSecureField("Password", text: $password)
                .validation(.required, .minLength(8))
            
            SubmitButton("Sign In") {
                // Handle login
            }
        }
    }
}
```

### Form with Sections

```swift
FormContainer(title: "Registration") {
    FormSection("Personal Info") {
        FormTextField("Full Name", text: $name)
            .validation(.required)
        
        FormPhoneField("Phone", phoneNumber: $phone, countryCode: $country)
        
        FormDatePicker("Birth Date", selection: $birthDate)
    }
    
    FormSection("Account") {
        FormTextField("Email", text: $email)
            .validation(.required, .email)
        
        FormSecureField("Password", text: $password, showStrengthIndicator: true)
            .validation(.required, .strongPassword)
    }
}
```

---

## Field Types

### Text Fields

```swift
// Standard text
FormTextField("Name", text: $name)

// Email with validation
FormTextField("Email", text: $email)
    .keyboardType(.emailAddress)
    .textContentType(.emailAddress)
    .validation(.email)

// Password with strength indicator
FormSecureField("Password", text: $password, showStrengthIndicator: true)

// Phone with country picker
FormPhoneField("Phone", phoneNumber: $phone, countryCode: $country)

// Multiline text
FormTextField("Bio", text: $bio)
    .lineLimit(5...10)
```

### Selection Fields

```swift
// Single select dropdown
FormPicker("Country", selection: $country, options: countries)

// Multi-select with chips
FormMultiSelect("Skills", selection: $skills, options: allSkills, style: .chips)

// Radio buttons
FormRadioGroup("Plan", selection: $plan, options: [
    RadioOption(value: "free", label: "Free", description: "Basic features"),
    RadioOption(value: "pro", label: "Pro", description: "$9.99/month")
], style: .cards)

// Toggle
FormToggleField("Accept Terms", isOn: $acceptTerms, style: .checkbox)
```

### Date & Time

```swift
// Date picker
FormDatePicker("Birth Date", selection: $date)

// Time picker
FormTimePicker("Alarm", time: $time, style: .hourMinute)

// Time range
FormTimeRangePicker("Working Hours", startTime: $start, endTime: $end)
```

### Special Fields

```swift
// Rating
FormRatingField("Rate this app", rating: $rating, style: .stars)

// Slider with labels
FormSliderField("Budget", value: $budget, range: 0...1000, style: .labeled)

// Credit card
FormCreditCardField("Card", cardNumber: $card, expiryDate: $expiry, cvv: $cvv)

// Signature
FormSignatureField("Signature", signature: $signature)

// File upload
FormFileUpload("Documents", files: $files, allowedTypes: [.pdf, .image])

// OTP
FormOTPField("Verification Code", code: $otp, length: 6)
```

---

## Validation

### Built-in Rules

```swift
.validation(.required)                    // Must not be empty
.validation(.email)                       // Valid email format
.validation(.phone)                       // Valid phone number
.validation(.url)                         // Valid URL
.validation(.minLength(8))                // Minimum length
.validation(.maxLength(100))              // Maximum length
.validation(.min(18))                     // Minimum value
.validation(.max(120))                    // Maximum value
.validation(.pattern(#"^\d{5}$"#))       // Regex pattern
.validation(.creditCard)                  // Valid card number
.validation(.strongPassword)              // Password strength
```

### Custom Validation

```swift
FormTextField("Username", text: $username)
    .validation(.custom { value in
        if value.contains(" ") {
            return "Username cannot contain spaces"
        }
        return nil // Valid
    })
```

### Async Validation

```swift
FormTextField("Username", text: $username)
    .asyncValidation { value in
        // Check if username is available
        let isAvailable = await API.checkUsername(value)
        return isAvailable ? nil : "Username already taken"
    }
```

### Field Dependencies

```swift
FormSecureField("Confirm Password", text: $confirmPassword)
    .validation(.matches(field: "password", message: "Passwords don't match"))
```

---

## Advanced Features

### Multi-Step Forms

```swift
MultiStepForm(state: formState, indicatorStyle: .numbered) {
    FormStep("Personal", icon: "person") {
        FormTextField("Name", text: $name)
        FormTextField("Email", text: $email)
    }
    
    FormStep("Address", icon: "location") {
        FormAddressField(address: $address)
    }
    
    FormStep("Payment", icon: "creditcard") {
        FormCreditCardField("Card", cardNumber: $card, ...)
    }
}
```

### JSON-Driven Forms

```swift
let schema = """
{
    "id": "contact",
    "title": "Contact Us",
    "fields": [
        {"id": "name", "type": "text", "label": "Name", "required": true},
        {"id": "email", "type": "email", "label": "Email", "required": true},
        {"id": "message", "type": "textarea", "label": "Message"}
    ]
}
"""

let formSchema = try JSONFormBuilder.parse(schema)
JSONFormView(schema: formSchema, state: formState)
```

### Form Analytics

```swift
// Enable analytics
FormAnalytics.shared.addProvider(ConsoleAnalyticsProvider())

// Track form
FormContainer(title: "Survey")
    .trackAnalytics(formId: "survey-form", totalFields: 10)

// View analytics dashboard
FormAnalyticsDashboard(formId: "survey-form")
```

### Form DSL

```swift
FormContainer(title: "Quick Form") {
    FormSection("Info") {
        Field("Name", required: true) {
            TextField("", text: $name)
        }
        
        FormRow {
            Field("First") { TextField("", text: $first) }
            Field("Last") { TextField("", text: $last) }
        }
    }
    
    ConditionalField(when: showOptional) {
        Field("Optional") { TextField("", text: $optional) }
    }
    
    SubmitButton("Submit", icon: "paperplane")
}
```

### Theming

```swift
// Use built-in theme
FormContainer(theme: .dark) { ... }

// Custom theme
let customTheme = FormTheme(
    primaryColor: .blue,
    errorColor: .red,
    successColor: .green,
    labelColor: .primary,
    backgroundColor: .clear,
    borderColor: .gray.opacity(0.3),
    cornerRadius: 12,
    spacing: 16
)

FormContainer(theme: customTheme) { ... }
```

---

## Accessibility

SwiftUI Forms Kit is built with accessibility in mind:

```swift
// All fields have proper labels
FormTextField("Email", text: $email)
    .accessibilityHint("Enter your email address")

// Error announcements
.accessibilityAnnouncement(error)

// VoiceOver support for all interactions
// Dynamic Type support
// Reduce Motion support
```

---

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS | 16.0+ |
| macOS | 13.0+ |
| tvOS | 16.0+ |
| watchOS | 9.0+ |

---

## Documentation

📖 [Full Documentation](https://github.com/muhittincamdali/SwiftUI-Forms-Kit/wiki)

---

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) first.

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/muhittincamdali">Muhittin Camdali</a>
</p>

<p align="center">
  <a href="https://github.com/muhittincamdali/SwiftUI-Forms-Kit/stargazers">⭐ Star us on GitHub!</a>
</p>
