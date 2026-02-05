import SwiftUI

// MARK: - Toggle Style

/// Visual style for toggle/checkbox
public enum FormToggleStyle {
    case toggle
    case checkbox
    case switch_
    case labeled
}

// MARK: - Single Toggle

/// Single toggle/checkbox field
public struct FormToggleField: View {
    @Binding private var isOn: Bool
    
    private let label: String
    private let description: String?
    private let style: FormToggleStyle
    private let icon: String?
    private let required: Bool
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        isOn: Binding<Bool>,
        description: String? = nil,
        style: FormToggleStyle = .toggle,
        icon: String? = nil,
        required: Bool = false
    ) {
        self.label = label
        self._isOn = isOn
        self.description = description
        self.style = style
        self.icon = icon
        self.required = required
    }
    
    public var body: some View {
        switch style {
        case .toggle:
            standardToggle
        case .checkbox:
            checkboxToggle
        case .switch_:
            switchToggle
        case .labeled:
            labeledToggle
        }
    }
    
    // MARK: - Standard Toggle
    
    private var standardToggle: some View {
        Toggle(isOn: $isOn) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(theme.primaryColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(label)
                        if required {
                            Text("*")
                                .foregroundColor(theme.errorColor)
                        }
                    }
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .tint(theme.primaryColor)
    }
    
    // MARK: - Checkbox
    
    private var checkboxToggle: some View {
        Button(action: { isOn.toggle(); hapticFeedback() }) {
            HStack(spacing: 12) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isOn ? theme.primaryColor : theme.borderColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isOn {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.primaryColor)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
                .animation(.spring(response: 0.2), value: isOn)
                
                // Label
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        if let icon = icon {
                            Image(systemName: icon)
                                .foregroundColor(.secondary)
                        }
                        Text(label)
                            .foregroundColor(.primary)
                        if required {
                            Text("*")
                                .foregroundColor(theme.errorColor)
                        }
                    }
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
    
    // MARK: - Switch
    
    private var switchToggle: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(theme.primaryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(label)
                    if required {
                        Text("*")
                            .foregroundColor(theme.errorColor)
                    }
                }
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Custom switch
            Button(action: { isOn.toggle(); hapticFeedback() }) {
                Capsule()
                    .fill(isOn ? theme.primaryColor : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .shadow(radius: 2)
                            .frame(width: 26, height: 26)
                            .offset(x: isOn ? 10 : -10),
                        alignment: isOn ? .trailing : .leading
                    )
                    .animation(.spring(response: 0.2), value: isOn)
            }
        }
    }
    
    // MARK: - Labeled
    
    private var labeledToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .foregroundColor(.secondary)
                    }
                    Text(label)
                    if required {
                        Text("*")
                            .foregroundColor(theme.errorColor)
                    }
                }
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // On/Off buttons
            HStack(spacing: 0) {
                Button(action: { isOn = false; hapticFeedback() }) {
                    Text("Off")
                        .font(.subheadline.weight(isOn ? .regular : .semibold))
                        .foregroundColor(isOn ? .secondary : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(isOn ? Color.clear : Color.gray)
                        )
                }
                
                Button(action: { isOn = true; hapticFeedback() }) {
                    Text("On")
                        .font(.subheadline.weight(isOn ? .semibold : .regular))
                        .foregroundColor(isOn ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(isOn ? theme.primaryColor : Color.clear)
                        )
                }
            }
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(Color.gray.opacity(0.15))
            )
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Toggle Group

/// Group of toggles with optional select all
public struct FormToggleGroup: View {
    @Binding private var selections: Set<String>
    
    private let label: String
    private let options: [ToggleGroupOption]
    private let showSelectAll: Bool
    
    @Environment(\.formTheme) private var theme
    
    public struct ToggleGroupOption: Identifiable {
        public let id: String
        public let label: String
        public let description: String?
        public let icon: String?
        
        public init(_ id: String, label: String, description: String? = nil, icon: String? = nil) {
            self.id = id
            self.label = label
            self.description = description
            self.icon = icon
        }
    }
    
    public init(
        _ label: String,
        selections: Binding<Set<String>>,
        options: [ToggleGroupOption],
        showSelectAll: Bool = false
    ) {
        self.label = label
        self._selections = selections
        self.options = options
        self.showSelectAll = showSelectAll
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
                
                Spacer()
                
                if showSelectAll {
                    Button(action: toggleAll) {
                        Text(allSelected ? "Deselect All" : "Select All")
                            .font(.caption)
                            .foregroundColor(theme.primaryColor)
                    }
                }
            }
            
            // Options
            VStack(spacing: 8) {
                ForEach(options) { option in
                    toggleRow(for: option)
                }
            }
        }
    }
    
    private func toggleRow(for option: ToggleGroupOption) -> some View {
        let isSelected = selections.contains(option.id)
        
        return Button(action: { toggle(option.id) }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? theme.primaryColor : theme.borderColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.primaryColor)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
                
                if let icon = option.icon {
                    Image(systemName: icon)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .foregroundColor(.primary)
                    if let description = option.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
    }
    
    private var allSelected: Bool {
        options.allSatisfy { selections.contains($0.id) }
    }
    
    private func toggle(_ id: String) {
        if selections.contains(id) {
            selections.remove(id)
        } else {
            selections.insert(id)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func toggleAll() {
        if allSelected {
            selections.removeAll()
        } else {
            selections = Set(options.map { $0.id })
        }
    }
}

// MARK: - Terms Toggle

/// Specialized toggle for accepting terms
public struct FormTermsToggle: View {
    @Binding private var accepted: Bool
    
    private let termsText: String
    private let termsURL: URL?
    private let privacyURL: URL?
    
    @Environment(\.formTheme) private var theme
    @Environment(\.openURL) private var openURL
    
    public init(
        accepted: Binding<Bool>,
        termsText: String = "I agree to the",
        termsURL: URL? = nil,
        privacyURL: URL? = nil
    ) {
        self._accepted = accepted
        self.termsText = termsText
        self.termsURL = termsURL
        self.privacyURL = privacyURL
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            Button(action: { accepted.toggle() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(accepted ? theme.primaryColor : theme.borderColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if accepted {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(theme.primaryColor)
                            .frame(width: 22, height: 22)
                        
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Text with links
            Text(termsAttributedString)
                .font(.subheadline)
        }
    }
    
    private var termsAttributedString: AttributedString {
        var result = AttributedString(termsText + " ")
        
        if let termsURL = termsURL {
            var terms = AttributedString("Terms of Service")
            terms.foregroundColor = theme.primaryColor
            terms.link = termsURL
            result += terms
        }
        
        if termsURL != nil && privacyURL != nil {
            result += AttributedString(" and ")
        }
        
        if let privacyURL = privacyURL {
            var privacy = AttributedString("Privacy Policy")
            privacy.foregroundColor = theme.primaryColor
            privacy.link = privacyURL
            result += privacy
        }
        
        return result
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        FormToggleField("Enable notifications", isOn: .constant(true))
        
        FormToggleField(
            "Accept terms",
            isOn: .constant(false),
            description: "You must accept to continue",
            style: .checkbox,
            required: true
        )
        
        FormToggleField(
            "Dark mode",
            isOn: .constant(true),
            style: .switch_,
            icon: "moon.fill"
        )
        
        FormToggleField(
            "Auto-save",
            isOn: .constant(true),
            style: .labeled
        )
        
        FormTermsToggle(
            accepted: .constant(false),
            termsURL: URL(string: "https://example.com/terms"),
            privacyURL: URL(string: "https://example.com/privacy")
        )
    }
    .padding()
}
