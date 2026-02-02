import SwiftUI

// MARK: - Form Text Field

/// A validated text input field for forms
public struct FormTextField: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let placeholder: String
    public let rules: [ValidationRule]
    public let keyboardType: UIKeyboardType
    public let textContentType: UITextContentType?
    public let autocapitalization: TextInputAutocapitalization
    public let maxLength: Int?
    public let prefix: String?
    public let suffix: String?
    public let isMultiline: Bool
    public let lineLimit: Int

    @State private var isFocused: Bool = false

    public init(
        key: String,
        title: String,
        placeholder: String = "",
        rules: [ValidationRule] = [],
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        maxLength: Int? = nil,
        prefix: String? = nil,
        suffix: String? = nil,
        isMultiline: Bool = false,
        lineLimit: Int = 1
    ) {
        self.key = key
        self.title = title
        self.placeholder = placeholder
        self.rules = rules
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.maxLength = maxLength
        self.prefix = prefix
        self.suffix = suffix
        self.isMultiline = isMultiline
        self.lineLimit = lineLimit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title label
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            // Input container
            HStack(spacing: 8) {
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundColor(.secondary)
                        .font(theme.inputFont)
                }

                if isMultiline {
                    TextEditor(text: textBinding)
                        .font(theme.inputFont)
                        .frame(minHeight: 80)
                        .lineLimit(lineLimit...lineLimit * 3)
                } else {
                    TextField(placeholder, text: textBinding)
                        .font(theme.inputFont)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                        .textInputAutocapitalization(autocapitalization)
                        .onSubmit {
                            formState.touchField(key)
                        }
                }

                if let suffix = suffix {
                    Text(suffix)
                        .foregroundColor(.secondary)
                        .font(theme.inputFont)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(theme.backgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )

            // Character count
            if let maxLength = maxLength {
                let currentLength = (formState.value(forKey: key) as? String)?.count ?? 0
                Text("\(currentLength)/\(maxLength)")
                    .font(.caption2)
                    .foregroundColor(currentLength > maxLength ? theme.errorColor : .secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            formState.registerField(key, rules: rules)
        }
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
    }

    // MARK: - Private Helpers

    private var textBinding: Binding<String> {
        Binding<String>(
            get: {
                formState.value(forKey: key) as? String ?? ""
            },
            set: { newValue in
                var truncated = newValue
                if let maxLength = maxLength {
                    truncated = String(newValue.prefix(maxLength))
                }
                formState.setValue(truncated, forKey: key)
            }
        )
    }

    private var borderColor: Color {
        if errorMessage != nil { return theme.errorColor }
        if isFocused { return theme.primaryColor }
        return Color.gray.opacity(0.3)
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
