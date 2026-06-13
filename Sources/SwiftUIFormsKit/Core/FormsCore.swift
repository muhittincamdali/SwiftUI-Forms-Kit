import Foundation

/// Main entry point for the SwiftUI Forms Kit toolkit.
public enum SwiftUIFormsKit {
    public static let version = "2.0.0"
}

/// A protocol for form validation rules.
public protocol FormValidationRule: Sendable {
    func validate(_ value: Any?) -> Bool
    var errorMessage: String { get }
}
