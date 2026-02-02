import SwiftUI

// MARK: - Form Secure Field

/// A password input field with optional visibility toggle
public struct FormSecureField: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let placeholder: String
    public let rules: [ValidationRule]
    public let showToggle: Bool

    @State private var isRevealed: Bool = false

    public init(
        key: String,
        title: String,
        placeholder: String = "",
        rules: [ValidationRule] = [],
        showToggle: Bool = true
    ) {
        self.key = key
        self.title = title
        self.placeholder = placeholder
        self.rules = rules
        self.showToggle = showToggle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                if isRevealed {
                    TextField(placeholder, text: formState.stringBinding(forKey: key))
                        .font(theme.inputFont)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(placeholder, text: formState.stringBinding(forKey: key))
                        .font(theme.inputFont)
                        .textContentType(.password)
                }

                if showToggle {
                    Button(action: { isRevealed.toggle() }) {
                        Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(theme.backgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )

            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
            }
        }
        .onAppear {
            formState.registerField(key, rules: rules)
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return theme.errorColor }
        return Color.gray.opacity(0.3)
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
