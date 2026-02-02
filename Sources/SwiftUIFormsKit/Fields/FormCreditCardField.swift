import SwiftUI

// MARK: - Card Brand

/// Supported credit card brands
public enum CardBrand: String, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case unknown = "Unknown"

    public var icon: String {
        switch self {
        case .visa: return "creditcard"
        case .mastercard: return "creditcard.fill"
        case .amex: return "creditcard.trianglebadge.exclamationmark"
        case .discover: return "creditcard.circle"
        case .unknown: return "creditcard"
        }
    }

    /// Detect card brand from the card number prefix
    public static func detect(from number: String) -> CardBrand {
        let cleaned = number.replacingOccurrences(of: " ", with: "")
        if cleaned.hasPrefix("4") { return .visa }
        if let prefix = Int(String(cleaned.prefix(2))) {
            if (51...55).contains(prefix) { return .mastercard }
        }
        if cleaned.hasPrefix("34") || cleaned.hasPrefix("37") { return .amex }
        if cleaned.hasPrefix("6011") || cleaned.hasPrefix("65") { return .discover }
        return .unknown
    }
}

// MARK: - Luhn Algorithm

/// Validates credit card numbers using the Luhn algorithm
public enum LuhnValidator {
    public static func isValid(_ number: String) -> Bool {
        let cleaned = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard cleaned.count >= 13, cleaned.count <= 19 else { return false }

        var sum = 0
        let reversed = cleaned.reversed().map { Int(String($0)) ?? 0 }

        for (index, digit) in reversed.enumerated() {
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

// MARK: - Form Credit Card Field

/// A specialized input field for credit card numbers with live formatting
public struct FormCreditCardField: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let rules: [ValidationRule]
    public let showCardBrand: Bool
    public let supportedBrands: [CardBrand]

    @State private var detectedBrand: CardBrand = .unknown

    public init(
        key: String,
        title: String,
        rules: [ValidationRule] = [],
        showCardBrand: Bool = true,
        supportedBrands: [CardBrand] = CardBrand.allCases
    ) {
        self.key = key
        self.title = title
        self.rules = rules
        self.showCardBrand = showCardBrand
        self.supportedBrands = supportedBrands
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            HStack(spacing: 8) {
                if showCardBrand {
                    Image(systemName: detectedBrand.icon)
                        .foregroundColor(detectedBrand == .unknown ? .secondary : theme.primaryColor)
                        .frame(width: 24)
                        .animation(.easeInOut, value: detectedBrand)
                }

                TextField("1234 5678 9012 3456", text: cardNumberBinding)
                    .font(.system(.body, design: .monospaced))
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(theme.backgroundColor)
            .cornerRadius(theme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )

            if showCardBrand && detectedBrand != .unknown {
                Text(detectedBrand.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
            }
        }
        .onAppear {
            let allRules = rules + [luhnRule]
            formState.registerField(key, rules: allRules)
        }
    }

    // MARK: - Private

    private var cardNumberBinding: Binding<String> {
        Binding<String>(
            get: {
                formState.value(forKey: key) as? String ?? ""
            },
            set: { newValue in
                let cleaned = newValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                let truncated = String(cleaned.prefix(16))
                let formatted = formatCardNumber(truncated)
                formState.setValue(formatted, forKey: key)
                detectedBrand = CardBrand.detect(from: truncated)
            }
        )
    }

    private func formatCardNumber(_ number: String) -> String {
        var result = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result.append(char)
        }
        return result
    }

    private var luhnRule: ValidationRule {
        .custom(identifier: "luhn", message: "Invalid card number") { value in
            guard let number = value as? String, !number.isEmpty else { return .valid }
            return LuhnValidator.isValid(number) ? .valid : .invalid("Invalid card number")
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
