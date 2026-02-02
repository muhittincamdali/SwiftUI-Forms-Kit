import SwiftUI

// MARK: - Form Date Picker

/// A date picker field with optional range constraints
public struct FormDatePicker: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let rules: [ValidationRule]
    public let displayedComponents: DatePickerComponents
    public let minimumDate: Date?
    public let maximumDate: Date?

    public init(
        key: String,
        title: String,
        rules: [ValidationRule] = [],
        displayedComponents: DatePickerComponents = .date,
        minimumDate: Date? = nil,
        maximumDate: Date? = nil
    ) {
        self.key = key
        self.title = title
        self.rules = rules
        self.displayedComponents = displayedComponents
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            Group {
                if let min = minimumDate, let max = maximumDate {
                    DatePicker(
                        "",
                        selection: formState.dateBinding(forKey: key),
                        in: min...max,
                        displayedComponents: displayedComponents
                    )
                } else if let min = minimumDate {
                    DatePicker(
                        "",
                        selection: formState.dateBinding(forKey: key),
                        in: min...,
                        displayedComponents: displayedComponents
                    )
                } else if let max = maximumDate {
                    DatePicker(
                        "",
                        selection: formState.dateBinding(forKey: key),
                        in: ...max,
                        displayedComponents: displayedComponents
                    )
                } else {
                    DatePicker(
                        "",
                        selection: formState.dateBinding(forKey: key),
                        displayedComponents: displayedComponents
                    )
                }
            }
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.backgroundColor)
            .cornerRadius(theme.cornerRadius)

            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
            }
        }
        .onAppear {
            formState.registerField(key, rules: rules, defaultValue: Date())
        }
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
