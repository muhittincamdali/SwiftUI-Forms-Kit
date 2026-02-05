// SwiftUI Forms Kit - Advanced form building for SwiftUI
// Copyright (c) 2024 Muhittin Camdali. MIT License.

import SwiftUI

// MARK: - Core
@_exported import struct SwiftUI.Binding
@_exported import class SwiftUI.ObservableObject

// MARK: - Public API

/// SwiftUI Forms Kit version
public let version = "2.0.0"

/// Check if running on iOS 17+
public var supportsLatestFeatures: Bool {
    if #available(iOS 17.0, *) {
        return true
    }
    return false
}

// MARK: - Module Exports

// Core
public typealias FormsKit = SwiftUIFormsKit

// MARK: - Convenience Extensions

public extension View {
    /// Apply form theme to view hierarchy
    func formTheme(_ theme: FormTheme) -> some View {
        environment(\.formTheme, theme)
    }
    
    /// Add form validation state
    func formState(_ state: FormState) -> some View {
        environmentObject(state)
    }
}

// MARK: - Quick Start Helpers

/// Create a simple text field with validation
public func textField(
    _ label: String,
    text: Binding<String>,
    validation: [ValidationRule] = []
) -> FormTextField {
    var field = FormTextField(label, text: text)
    // Apply validation rules
    return field
}

/// Create a secure password field
public func passwordField(
    _ label: String,
    password: Binding<String>,
    showStrength: Bool = true
) -> FormSecureField {
    FormSecureField(label, text: password, showStrengthIndicator: showStrength)
}

/// Create a date picker field
public func dateField(
    _ label: String,
    date: Binding<Date>,
    range: ClosedRange<Date>? = nil
) -> FormDatePicker {
    FormDatePicker(label, selection: date, in: range ?? Date.distantPast...Date.distantFuture)
}

// MARK: - Form Presets

/// Common form configurations
public enum FormPreset {
    case login
    case registration
    case contact
    case checkout
    case profile
    case feedback
    
    public var theme: FormTheme {
        switch self {
        case .login, .registration:
            return .default
        case .checkout:
            return FormTheme(
                primaryColor: .green,
                errorColor: .red,
                successColor: .green
            )
        case .contact, .feedback:
            return FormTheme(
                primaryColor: .blue,
                cornerRadius: 12
            )
        case .profile:
            return FormTheme(
                primaryColor: .purple,
                backgroundColor: .clear
            )
        }
    }
}

// MARK: - Form Templates

/// Pre-built form templates
public struct FormTemplates {
    
    /// Login form template
    public static func loginForm(
        email: Binding<String>,
        password: Binding<String>,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            FormTextField("Email", text: email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
            
            FormSecureField("Password", text: password)
            
            Button(action: onSubmit) {
                Text("Sign In")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    /// Contact form template
    public static func contactForm(
        name: Binding<String>,
        email: Binding<String>,
        message: Binding<String>,
        onSubmit: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            FormTextField("Name", text: name)
            
            FormTextField("Email", text: email)
                .keyboardType(.emailAddress)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Message")
                    .font(.subheadline.weight(.medium))
                TextEditor(text: message)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
            }
            
            Button(action: onSubmit) {
                Text("Send Message")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Validation Helpers

/// Common validation patterns
public struct ValidationPatterns {
    public static let email = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
    public static let phone = #"^\+?[1-9]\d{1,14}$"#
    public static let url = #"^https?://[^\s/$.?#].[^\s]*$"#
    public static let postalCodeUS = #"^\d{5}(-\d{4})?$"#
    public static let postalCodeUK = #"^[A-Z]{1,2}\d[A-Z\d]? ?\d[A-Z]{2}$"#
    public static let creditCard = #"^\d{13,19}$"#
    public static let cvv = #"^\d{3,4}$"#
    public static let strongPassword = #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"#
}

// MARK: - Debug Helpers

#if DEBUG
public extension FormState {
    /// Print current form state
    func debugPrint() {
        print("=== Form State Debug ===")
        print("Is Valid: \(isValid)")
        print("Is Submitting: \(isSubmitting)")
        print("Fields: \(fields.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
        print("Errors: \(errors)")
        print("========================")
    }
}
#endif
