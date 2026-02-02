import SwiftUI

// MARK: - Form Picker

/// A dropdown/wheel picker for selecting from predefined options
public struct FormPicker<T: Hashable>: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let options: [T]
    public let rules: [ValidationRule]
    public let labelProvider: (T) -> String
    public let pickerStyle: PickerStyleOption

    public enum PickerStyleOption {
        case menu
        case wheel
        case segmented
        case inline
    }

    public init(
        key: String,
        title: String,
        options: [T],
        rules: [ValidationRule] = [],
        pickerStyle: PickerStyleOption = .menu,
        labelProvider: @escaping (T) -> String
    ) {
        self.key = key
        self.title = title
        self.options = options
        self.rules = rules
        self.pickerStyle = pickerStyle
        self.labelProvider = labelProvider
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            pickerView
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
            formState.registerField(key, rules: rules)
        }
    }

    @ViewBuilder
    private var pickerView: some View {
        let binding = Binding<T?>(
            get: { formState.value(forKey: key) as? T },
            set: { newValue in
                formState.setValue(newValue, forKey: key)
                formState.touchField(key)
            }
        )

        switch pickerStyle {
        case .menu:
            Picker(title, selection: binding) {
                Text("Select...").tag(nil as T?)
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(option as T?)
                }
            }
            .pickerStyle(.menu)
        case .wheel:
            Picker(title, selection: binding) {
                Text("Select...").tag(nil as T?)
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(option as T?)
                }
            }
            .pickerStyle(.wheel)
        case .segmented:
            Picker(title, selection: binding) {
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(option as T?)
                }
            }
            .pickerStyle(.segmented)
        case .inline:
            Picker(title, selection: binding) {
                Text("Select...").tag(nil as T?)
                ForEach(options, id: \.self) { option in
                    Text(labelProvider(option)).tag(option as T?)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}

// MARK: - String convenience

extension FormPicker where T == String {
    public init(
        key: String,
        title: String,
        options: [String],
        rules: [ValidationRule] = [],
        pickerStyle: PickerStyleOption = .menu
    ) {
        self.key = key
        self.title = title
        self.options = options
        self.rules = rules
        self.pickerStyle = pickerStyle
        self.labelProvider = { $0 }
    }
}
