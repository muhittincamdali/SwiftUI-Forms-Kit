import SwiftUI

// MARK: - Radio Group Style

/// Visual style for radio button groups
public enum RadioGroupStyle {
    case standard
    case cards
    case segmented
    case buttons
}

// MARK: - Radio Option

/// Single radio option with optional description
public struct RadioOption<Value: Hashable>: Identifiable {
    public let id: Value
    public let label: String
    public let description: String?
    public let icon: String?
    public let disabled: Bool
    
    public init(
        value: Value,
        label: String,
        description: String? = nil,
        icon: String? = nil,
        disabled: Bool = false
    ) {
        self.id = value
        self.label = label
        self.description = description
        self.icon = icon
        self.disabled = disabled
    }
}

// MARK: - Radio Group

/// Single selection radio button group
public struct FormRadioGroup<Value: Hashable>: View {
    @Binding private var selection: Value?
    
    private let label: String
    private let options: [RadioOption<Value>]
    private let style: RadioGroupStyle
    private let horizontal: Bool
    private let required: Bool
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        selection: Binding<Value?>,
        options: [RadioOption<Value>],
        style: RadioGroupStyle = .standard,
        horizontal: Bool = false,
        required: Bool = false
    ) {
        self.label = label
        self._selection = selection
        self.options = options
        self.style = style
        self.horizontal = horizontal
        self.required = required
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            if !label.isEmpty {
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.labelColor)
                    
                    if required {
                        Text("*")
                            .foregroundColor(theme.errorColor)
                    }
                }
            }
            
            // Options
            switch style {
            case .standard:
                standardView
            case .cards:
                cardsView
            case .segmented:
                segmentedView
            case .buttons:
                buttonsView
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label)
    }
    
    // MARK: - Standard View
    
    private var standardView: some View {
        let layout = horizontal ? AnyLayout(HStackLayout(spacing: 16)) : AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
        
        return layout {
            ForEach(options) { option in
                standardRadioButton(option)
            }
        }
    }
    
    private func standardRadioButton(_ option: RadioOption<Value>) -> some View {
        let isSelected = selection == option.id
        
        return Button(action: { select(option) }) {
            HStack(spacing: 10) {
                // Radio circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? theme.primaryColor : theme.borderColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(theme.primaryColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .foregroundColor(.secondary)
                        }
                        Text(option.label)
                            .foregroundColor(option.disabled ? .secondary : .primary)
                    }
                    
                    if let description = option.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(option.disabled)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
    
    // MARK: - Cards View
    
    private var cardsView: some View {
        VStack(spacing: 8) {
            ForEach(options) { option in
                cardRadioButton(option)
            }
        }
    }
    
    private func cardRadioButton(_ option: RadioOption<Value>) -> some View {
        let isSelected = selection == option.id
        
        return Button(action: { select(option) }) {
            HStack {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? theme.primaryColor : .secondary)
                        .frame(width: 40)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .fontWeight(.medium)
                        .foregroundColor(option.disabled ? .secondary : .primary)
                    
                    if let description = option.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? theme.primaryColor : .gray.opacity(0.4))
                    .font(.title3)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(isSelected ? theme.primaryColor : theme.borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(isSelected ? theme.primaryColor.opacity(0.05) : Color.clear)
            )
        }
        .disabled(option.disabled)
    }
    
    // MARK: - Segmented View
    
    private var segmentedView: some View {
        HStack(spacing: 0) {
            ForEach(options) { option in
                segmentButton(option)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(Color.gray.opacity(0.15))
        )
    }
    
    private func segmentButton(_ option: RadioOption<Value>) -> some View {
        let isSelected = selection == option.id
        
        return Button(action: { select(option) }) {
            HStack(spacing: 4) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(option.label)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius - 2)
                    .fill(isSelected ? theme.primaryColor : Color.clear)
            )
            .padding(2)
        }
        .disabled(option.disabled)
    }
    
    // MARK: - Buttons View
    
    private var buttonsView: some View {
        HStack(spacing: 8) {
            ForEach(options) { option in
                buttonStyle(option)
            }
        }
    }
    
    private func buttonStyle(_ option: RadioOption<Value>) -> some View {
        let isSelected = selection == option.id
        
        return Button(action: { select(option) }) {
            HStack(spacing: 4) {
                if let icon = option.icon {
                    Image(systemName: icon)
                }
                Text(option.label)
            }
            .font(.subheadline.weight(isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .white : theme.primaryColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? theme.primaryColor : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(theme.primaryColor, lineWidth: 1)
            )
        }
        .disabled(option.disabled)
    }
    
    // MARK: - Selection
    
    private func select(_ option: RadioOption<Value>) {
        guard !option.disabled else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            selection = option.id
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Convenience Initializer

public extension FormRadioGroup where Value == String {
    /// Create radio group from simple string options
    init(
        _ label: String,
        selection: Binding<String?>,
        options: [String],
        style: RadioGroupStyle = .standard,
        horizontal: Bool = false,
        required: Bool = false
    ) {
        self.init(
            label,
            selection: selection,
            options: options.map { RadioOption(value: $0, label: $0) },
            style: style,
            horizontal: horizontal,
            required: required
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var plan: String? = "pro"
        @State var gender: String?
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    FormRadioGroup(
                        "Select Plan",
                        selection: $plan,
                        options: [
                            RadioOption(value: "free", label: "Free", description: "Basic features", icon: "star"),
                            RadioOption(value: "pro", label: "Pro", description: "$9.99/month", icon: "star.fill"),
                            RadioOption(value: "team", label: "Team", description: "$29.99/month", icon: "person.3.fill")
                        ],
                        style: .cards
                    )
                    
                    FormRadioGroup(
                        "Gender",
                        selection: $gender,
                        options: ["Male", "Female", "Other"],
                        style: .segmented
                    )
                    
                    FormRadioGroup(
                        "Size",
                        selection: $gender,
                        options: ["S", "M", "L", "XL"],
                        style: .buttons
                    )
                }
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
