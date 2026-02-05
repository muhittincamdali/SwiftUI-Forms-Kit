import SwiftUI

// MARK: - Form DSL

/// Result builder for creating forms declaratively
@resultBuilder
public struct FormBuilder {
    public static func buildBlock<C0: View>(_ c0: C0) -> some View {
        c0
    }
    
    public static func buildBlock<C0: View, C1: View>(_ c0: C0, _ c1: C1) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View>(_ c0: C0, _ c1: C1, _ c2: C2) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
            c5
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
            c5
            c6
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
            c5
            c6
            c7
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
            c5
            c6
            c7
            c8
        }
    }
    
    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            c0
            c1
            c2
            c3
            c4
            c5
            c6
            c7
            c8
            c9
        }
    }
    
    public static func buildOptional<Content: View>(_ component: Content?) -> some View {
        component
    }
    
    public static func buildEither<TrueContent: View, FalseContent: View>(first component: TrueContent) -> some View {
        component
    }
    
    public static func buildEither<TrueContent: View, FalseContent: View>(second component: FalseContent) -> some View {
        component
    }
    
    public static func buildArray<Content: View>(_ components: [Content]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(components.indices, id: \.self) { index in
                components[index]
            }
        }
    }
}

// MARK: - Form Container

/// Main form container using DSL
public struct FormContainer<Content: View>: View {
    private let content: Content
    private let title: String?
    private let theme: FormTheme
    private let onSubmit: (() -> Void)?
    
    @State private var isSubmitting = false
    
    public init(
        title: String? = nil,
        theme: FormTheme = .default,
        onSubmit: (() -> Void)? = nil,
        @FormBuilder content: () -> Content
    ) {
        self.title = title
        self.theme = theme
        self.onSubmit = onSubmit
        self.content = content()
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                if let title = title {
                    Text(title)
                        .font(.title2.bold())
                }
                
                // Form content
                content
                    .environment(\.formTheme, theme)
                
                // Submit button
                if let onSubmit = onSubmit {
                    submitButton(action: onSubmit)
                }
            }
            .padding()
        }
    }
    
    private func submitButton(action: @escaping () -> Void) -> some View {
        Button(action: {
            isSubmitting = true
            action()
            isSubmitting = false
        }) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                }
                Text(isSubmitting ? "Submitting..." : "Submit")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.primaryColor)
            )
        }
        .disabled(isSubmitting)
    }
}

// MARK: - Form Section

/// Section container for grouping fields
public struct FormSection<Content: View>: View {
    private let title: String
    private let description: String?
    private let isCollapsible: Bool
    private let content: Content
    
    @State private var isExpanded = true
    @Environment(\.formTheme) private var theme
    
    public init(
        _ title: String,
        description: String? = nil,
        isCollapsible: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.isCollapsible = isCollapsible
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            header
            
            // Content
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
    
    private var header: some View {
        Button(action: {
            if isCollapsible {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isCollapsible {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
        }
        .disabled(!isCollapsible)
    }
}

// MARK: - Form Row

/// Horizontal row for inline fields
public struct FormRow<Content: View>: View {
    private let content: Content
    private let spacing: CGFloat
    
    public init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            content
        }
    }
}

// MARK: - Form Field Wrapper

/// Wrapper that adds common field functionality
public struct Field<Content: View>: View {
    private let label: String
    private let required: Bool
    private let error: String?
    private let helpText: String?
    private let content: Content
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        required: Bool = false,
        error: String? = nil,
        helpText: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.required = required
        self.error = error
        self.helpText = helpText
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
                
                if required {
                    Text("*")
                        .foregroundColor(theme.errorColor)
                }
            }
            
            // Content
            content
            
            // Help text
            if let helpText = helpText, error == nil {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Error
            if let error = error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(theme.errorColor)
            }
        }
    }
}

// MARK: - Conditional Field

/// Shows field based on condition
public struct ConditionalField<Content: View>: View {
    private let condition: Bool
    private let content: Content
    
    public init(when condition: Bool, @ViewBuilder content: () -> Content) {
        self.condition = condition
        self.content = content()
    }
    
    public var body: some View {
        if condition {
            content
                .transition(.opacity.combined(with: .slide))
        }
    }
}

// MARK: - Field Group

/// Groups related fields with visual connection
public struct FieldGroup<Content: View>: View {
    private let title: String?
    private let content: Content
    
    @Environment(\.formTheme) private var theme
    
    public init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.caption)
                    .textCase(.uppercase)
                    .foregroundColor(.secondary)
            }
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Submit Button

/// Styled submit button
public struct SubmitButton: View {
    private let title: String
    private let icon: String?
    private let isLoading: Bool
    private let isDisabled: Bool
    private let action: () -> Void
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ title: String = "Submit",
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                
                if let icon = icon, !isLoading {
                    Image(systemName: icon)
                }
                
                Text(isLoading ? "Processing..." : title)
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(isDisabled ? Color.gray : theme.primaryColor)
            )
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Form Divider

/// Visual divider between form sections
public struct FormDivider: View {
    private let label: String?
    
    public init(_ label: String? = nil) {
        self.label = label
    }
    
    public var body: some View {
        HStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    FormContainer(title: "Registration Form", theme: .default) {
        FormSection("Personal Info") {
            Field("Full Name", required: true) {
                TextField("Enter your name", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }
            
            FormRow {
                Field("First Name") {
                    TextField("First", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                }
                
                Field("Last Name") {
                    TextField("Last", text: .constant(""))
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        
        FormDivider("or")
        
        FormSection("Account", isCollapsible: true) {
            Field("Email", required: true, helpText: "We'll send verification here") {
                TextField("email@example.com", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }
            
            Field("Password", required: true, error: "Password must be 8+ characters") {
                SecureField("••••••••", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
            }
        }
        
        SubmitButton("Create Account", icon: "arrow.right")
    }
}
