import SwiftUI

// MARK: - Form Field Protocol

/// Protocol that all form fields must conform to
public protocol FormFieldView: View {
    /// The unique key identifying this field in the form state
    var key: String { get }
    /// The display title for this field
    var title: String { get }
    /// Validation rules applied to this field
    var rules: [ValidationRule] { get }
}

// MARK: - Form Step

/// Represents a single step in a multi-step form
public struct FormStep: Identifiable {
    public let id = UUID()
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let content: AnyView

    public init<Content: View>(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = AnyView(content())
    }
}

// MARK: - Form Result Builder

/// A result builder that enables declarative form construction
@resultBuilder
public struct FormContentBuilder {
    public static func buildBlock() -> [AnyView] {
        []
    }

    public static func buildBlock(_ components: AnyView...) -> [AnyView] {
        components
    }

    public static func buildBlock(_ components: [AnyView]...) -> [AnyView] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [AnyView]?) -> [AnyView] {
        component ?? []
    }

    public static func buildEither(first component: [AnyView]) -> [AnyView] {
        component
    }

    public static func buildEither(second component: [AnyView]) -> [AnyView] {
        component
    }

    public static func buildExpression<Content: View>(_ expression: Content) -> [AnyView] {
        [AnyView(expression)]
    }

    public static func buildArray(_ components: [[AnyView]]) -> [AnyView] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [AnyView]) -> [AnyView] {
        component
    }
}

// MARK: - Form Step Builder

/// A result builder specifically for creating form steps
@resultBuilder
public struct FormStepBuilder {
    public static func buildBlock(_ components: FormStep...) -> [FormStep] {
        components
    }

    public static func buildOptional(_ component: [FormStep]?) -> [FormStep] {
        component ?? []
    }

    public static func buildEither(first component: [FormStep]) -> [FormStep] {
        component
    }

    public static func buildEither(second component: [FormStep]) -> [FormStep] {
        component
    }

    public static func buildArray(_ components: [[FormStep]]) -> [FormStep] {
        components.flatMap { $0 }
    }
}

// MARK: - Form Builder View

/// The main form builder view that renders form fields declaratively
public struct FormBuilder: View {
    @ObservedObject private var state: FormState
    private let theme: FormTheme
    private let fields: [AnyView]
    private let onSubmit: (() -> Void)?
    private let submitTitle: String
    private let showSubmitButton: Bool

    public init(
        state: FormState,
        theme: FormTheme = .default,
        submitTitle: String = "Submit",
        showSubmitButton: Bool = true,
        onSubmit: (() -> Void)? = nil,
        @FormContentBuilder content: () -> [AnyView]
    ) {
        self.state = state
        self.theme = theme
        self.submitTitle = submitTitle
        self.showSubmitButton = showSubmitButton
        self.onSubmit = onSubmit
        self.fields = content()
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: theme.fieldSpacing) {
                ForEach(0..<fields.count, id: \.self) { index in
                    fields[index]
                        .environment(\.formTheme, theme)
                        .environmentObject(state)
                }

                if showSubmitButton {
                    submitButton
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var submitButton: some View {
        Button(action: {
            state.validateAll()
            if state.isValid {
                onSubmit?()
            }
        }) {
            Text(submitTitle)
                .font(theme.labelFont)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(state.isValid ? theme.primaryColor : theme.primaryColor.opacity(0.5))
                .cornerRadius(theme.cornerRadius)
        }
        .disabled(!state.isValid)
        .padding(.top, 8)
    }
}

// MARK: - Environment Key for Theme

private struct FormThemeKey: EnvironmentKey {
    static let defaultValue: FormTheme = .default
}

extension EnvironmentValues {
    public var formTheme: FormTheme {
        get { self[FormThemeKey.self] }
        set { self[FormThemeKey.self] = newValue }
    }
}
