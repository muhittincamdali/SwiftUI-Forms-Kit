import SwiftUI

// MARK: - Form OTP Field

/// A one-time password input field with individual digit boxes and auto-advance
public struct FormOTPField: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let rules: [ValidationRule]
    public let digitCount: Int
    public let boxSize: CGFloat
    public let spacing: CGFloat

    @State private var digits: [String]
    @FocusState private var focusedIndex: Int?

    public init(
        key: String,
        title: String,
        rules: [ValidationRule] = [],
        digitCount: Int = 6,
        boxSize: CGFloat = 48,
        spacing: CGFloat = 8
    ) {
        self.key = key
        self.title = title
        self.rules = rules
        self.digitCount = digitCount
        self.boxSize = boxSize
        self.spacing = spacing
        self._digits = State(initialValue: Array(repeating: "", count: digitCount))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            HStack(spacing: spacing) {
                ForEach(0..<digitCount, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .frame(maxWidth: .infinity)

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

    @ViewBuilder
    private func digitBox(at index: Int) -> some View {
        TextField("", text: digitBinding(at: index))
            .font(.system(.title2, design: .monospaced))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .frame(width: boxSize, height: boxSize)
            .background(theme.backgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(
                        focusedIndex == index ? theme.primaryColor :
                            (errorMessage != nil ? theme.errorColor : Color.gray.opacity(0.3)),
                        lineWidth: focusedIndex == index ? 2 : 1
                    )
            )
            .focused($focusedIndex, equals: index)
    }

    private func digitBinding(at index: Int) -> Binding<String> {
        Binding<String>(
            get: { digits[index] },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                if let lastChar = filtered.last {
                    digits[index] = String(lastChar)
                    updateFormValue()

                    // Auto-advance to next field
                    if index < digitCount - 1 {
                        focusedIndex = index + 1
                    } else {
                        focusedIndex = nil
                    }
                } else {
                    digits[index] = ""
                    updateFormValue()

                    // Auto-retreat to previous field
                    if index > 0 {
                        focusedIndex = index - 1
                    }
                }
            }
        )
    }

    private func updateFormValue() {
        let code = digits.joined()
        formState.setValue(code, forKey: key)
        if code.count == digitCount {
            formState.touchField(key)
        }
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
