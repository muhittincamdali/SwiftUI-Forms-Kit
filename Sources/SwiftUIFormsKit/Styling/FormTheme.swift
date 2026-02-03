import SwiftUI

// MARK: - Form Theme

/// Configuration object for form styling and appearance
public struct FormTheme: Equatable {
    public let primaryColor: Color
    public let errorColor: Color
    public let warningColor: Color
    public let successColor: Color
    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    public let fieldSpacing: CGFloat
    public let labelFont: Font
    public let inputFont: Font
    public let errorFont: Font
    public let animationDuration: Double

    public init(
        primaryColor: Color = .blue,
        errorColor: Color = .red,
        warningColor: Color = .orange,
        successColor: Color = .green,
        backgroundColor: Color = Color(.systemGray6),
        cornerRadius: CGFloat = 10,
        fieldSpacing: CGFloat = 16,
        labelFont: Font = .headline,
        inputFont: Font = .body,
        errorFont: Font = .caption,
        animationDuration: Double = 0.2
    ) {
        self.primaryColor = primaryColor
        self.errorColor = errorColor
        self.warningColor = warningColor
        self.successColor = successColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.fieldSpacing = fieldSpacing
        self.labelFont = labelFont
        self.inputFont = inputFont
        self.errorFont = errorFont
        self.animationDuration = animationDuration
    }

    // MARK: - Preset Themes

    /// Default form theme with system blue accent
    public static let `default` = FormTheme()

    /// Dark theme with high contrast
    public static let dark = FormTheme(
        primaryColor: .cyan,
        errorColor: .pink,
        warningColor: .yellow,
        successColor: .mint,
        backgroundColor: Color(.systemGray5),
        cornerRadius: 12,
        fieldSpacing: 18
    )

    /// Minimal theme with subtle styling
    public static let minimal = FormTheme(
        primaryColor: .primary,
        errorColor: .red,
        warningColor: .orange,
        successColor: .green,
        backgroundColor: .clear,
        cornerRadius: 0,
        fieldSpacing: 12
    )

    /// Rounded theme with larger corner radius
    public static let rounded = FormTheme(
        primaryColor: .indigo,
        errorColor: .red,
        warningColor: .orange,
        successColor: .green,
        backgroundColor: Color(.systemGray6),
        cornerRadius: 20,
        fieldSpacing: 20
    )

    public static func == (lhs: FormTheme, rhs: FormTheme) -> Bool {
        lhs.cornerRadius == rhs.cornerRadius &&
        lhs.fieldSpacing == rhs.fieldSpacing &&
        lhs.animationDuration == rhs.animationDuration
    }
}
