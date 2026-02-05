import SwiftUI

// MARK: - JSON Form Schema

/// Complete form schema that can be serialized to/from JSON
public struct FormSchema: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let version: String
    public let fields: [FieldSchema]
    public let sections: [SectionSchema]?
    public let validation: FormValidationSchema?
    public let submission: SubmissionSchema?
    public let styling: FormStylingSchema?
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        version: String = "1.0",
        fields: [FieldSchema],
        sections: [SectionSchema]? = nil,
        validation: FormValidationSchema? = nil,
        submission: SubmissionSchema? = nil,
        styling: FormStylingSchema? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.version = version
        self.fields = fields
        self.sections = sections
        self.validation = validation
        self.submission = submission
        self.styling = styling
    }
}

// MARK: - Field Schema

/// Schema for a single form field
public struct FieldSchema: Codable, Identifiable {
    public let id: String
    public let type: FieldType
    public let label: String
    public let placeholder: String?
    public let helpText: String?
    public let defaultValue: AnyCodable?
    public let required: Bool
    public let disabled: Bool
    public let hidden: Bool
    public let validation: [ValidationRuleSchema]?
    public let options: [OptionSchema]?
    public let properties: [String: AnyCodable]?
    public let dependsOn: DependencySchema?
    public let section: String?
    public let order: Int?
    
    public enum FieldType: String, Codable {
        case text
        case email
        case password
        case phone
        case number
        case currency
        case url
        case textarea
        case select
        case multiSelect
        case radio
        case checkbox
        case toggle
        case date
        case time
        case dateTime
        case slider
        case rating
        case file
        case image
        case signature
        case creditCard
        case address
        case otp
        case hidden
        case custom
    }
    
    public init(
        id: String,
        type: FieldType,
        label: String,
        placeholder: String? = nil,
        helpText: String? = nil,
        defaultValue: AnyCodable? = nil,
        required: Bool = false,
        disabled: Bool = false,
        hidden: Bool = false,
        validation: [ValidationRuleSchema]? = nil,
        options: [OptionSchema]? = nil,
        properties: [String: AnyCodable]? = nil,
        dependsOn: DependencySchema? = nil,
        section: String? = nil,
        order: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.placeholder = placeholder
        self.helpText = helpText
        self.defaultValue = defaultValue
        self.required = required
        self.disabled = disabled
        self.hidden = hidden
        self.validation = validation
        self.options = options
        self.properties = properties
        self.dependsOn = dependsOn
        self.section = section
        self.order = order
    }
}

// MARK: - Option Schema

/// Schema for select/radio options
public struct OptionSchema: Codable, Identifiable {
    public let id: String
    public let label: String
    public let value: AnyCodable
    public let disabled: Bool?
    public let icon: String?
    
    public init(id: String, label: String, value: AnyCodable, disabled: Bool? = nil, icon: String? = nil) {
        self.id = id
        self.label = label
        self.value = value
        self.disabled = disabled
        self.icon = icon
    }
}

// MARK: - Section Schema

/// Schema for grouping fields into sections
public struct SectionSchema: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String?
    public let collapsed: Bool?
    public let order: Int?
    
    public init(id: String, title: String, description: String? = nil, collapsed: Bool? = nil, order: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.collapsed = collapsed
        self.order = order
    }
}

// MARK: - Validation Rule Schema

/// Schema for validation rules
public struct ValidationRuleSchema: Codable {
    public let type: ValidationType
    public let value: AnyCodable?
    public let message: String?
    
    public enum ValidationType: String, Codable {
        case required
        case minLength
        case maxLength
        case min
        case max
        case pattern
        case email
        case url
        case phone
        case creditCard
        case custom
    }
    
    public init(type: ValidationType, value: AnyCodable? = nil, message: String? = nil) {
        self.type = type
        self.value = value
        self.message = message
    }
}

// MARK: - Dependency Schema

/// Schema for field dependencies
public struct DependencySchema: Codable {
    public let field: String
    public let condition: Condition
    public let value: AnyCodable?
    
    public enum Condition: String, Codable {
        case equals
        case notEquals
        case contains
        case notContains
        case greaterThan
        case lessThan
        case empty
        case notEmpty
    }
    
    public init(field: String, condition: Condition, value: AnyCodable? = nil) {
        self.field = field
        self.condition = condition
        self.value = value
    }
}

// MARK: - Form Validation Schema

/// Global form validation settings
public struct FormValidationSchema: Codable {
    public let validateOnBlur: Bool?
    public let validateOnChange: Bool?
    public let showErrorsOnSubmit: Bool?
    public let customValidators: [String]?
    
    public init(validateOnBlur: Bool? = nil, validateOnChange: Bool? = nil, showErrorsOnSubmit: Bool? = nil, customValidators: [String]? = nil) {
        self.validateOnBlur = validateOnBlur
        self.validateOnChange = validateOnChange
        self.showErrorsOnSubmit = showErrorsOnSubmit
        self.customValidators = customValidators
    }
}

// MARK: - Submission Schema

/// Form submission configuration
public struct SubmissionSchema: Codable {
    public let endpoint: String?
    public let method: String?
    public let headers: [String: String]?
    public let successMessage: String?
    public let redirectUrl: String?
    
    public init(endpoint: String? = nil, method: String? = nil, headers: [String: String]? = nil, successMessage: String? = nil, redirectUrl: String? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.headers = headers
        self.successMessage = successMessage
        self.redirectUrl = redirectUrl
    }
}

// MARK: - Form Styling Schema

/// Form styling configuration
public struct FormStylingSchema: Codable {
    public let primaryColor: String?
    public let errorColor: String?
    public let backgroundColor: String?
    public let borderColor: String?
    public let cornerRadius: Double?
    public let spacing: Double?
    
    public init(primaryColor: String? = nil, errorColor: String? = nil, backgroundColor: String? = nil, borderColor: String? = nil, cornerRadius: Double? = nil, spacing: Double? = nil) {
        self.primaryColor = primaryColor
        self.errorColor = errorColor
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.spacing = spacing
    }
}

// MARK: - Any Codable

/// Type-erased Codable wrapper
public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    public var stringValue: String? { value as? String }
    public var intValue: Int? { value as? Int }
    public var doubleValue: Double? { value as? Double }
    public var boolValue: Bool? { value as? Bool }
}

// MARK: - JSON Form Builder

/// Builds SwiftUI forms from JSON schema
public struct JSONFormBuilder {
    
    /// Parse JSON string to FormSchema
    public static func parse(_ json: String) throws -> FormSchema {
        guard let data = json.data(using: .utf8) else {
            throw JSONFormError.invalidJSON
        }
        return try JSONDecoder().decode(FormSchema.self, from: data)
    }
    
    /// Parse JSON data to FormSchema
    public static func parse(_ data: Data) throws -> FormSchema {
        try JSONDecoder().decode(FormSchema.self, from: data)
    }
    
    /// Load schema from URL
    public static func load(from url: URL) async throws -> FormSchema {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parse(data)
    }
    
    /// Export schema to JSON string
    public static func export(_ schema: FormSchema, prettyPrint: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        if prettyPrint {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        let data = try encoder.encode(schema)
        guard let json = String(data: data, encoding: .utf8) else {
            throw JSONFormError.encodingFailed
        }
        return json
    }
}

// MARK: - Errors

public enum JSONFormError: Error, LocalizedError {
    case invalidJSON
    case encodingFailed
    case fieldNotFound(String)
    case invalidFieldType(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidJSON: return "Invalid JSON format"
        case .encodingFailed: return "Failed to encode schema"
        case .fieldNotFound(let id): return "Field not found: \(id)"
        case .invalidFieldType(let type): return "Invalid field type: \(type)"
        }
    }
}

// MARK: - JSON Form View

/// Renders a form from JSON schema
public struct JSONFormView: View {
    @ObservedObject private var state: JSONFormState
    private let schema: FormSchema
    private let onSubmit: (([String: Any]) -> Void)?
    
    @Environment(\.formTheme) private var theme
    
    public init(
        schema: FormSchema,
        state: JSONFormState,
        onSubmit: (([String: Any]) -> Void)? = nil
    ) {
        self.schema = schema
        self.state = state
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                if !schema.title.isEmpty {
                    Text(schema.title)
                        .font(.title2.bold())
                }
                
                // Description
                if let description = schema.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Fields
                ForEach(sortedFields) { field in
                    if shouldShowField(field) {
                        fieldView(for: field)
                    }
                }
                
                // Submit button
                Button(action: submit) {
                    Text("Submit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                .fill(state.isValid ? theme.primaryColor : Color.gray)
                        )
                }
                .disabled(!state.isValid)
            }
            .padding()
        }
    }
    
    private var sortedFields: [FieldSchema] {
        schema.fields.sorted { ($0.order ?? 0) < ($1.order ?? 0) }
    }
    
    private func shouldShowField(_ field: FieldSchema) -> Bool {
        if field.hidden { return false }
        
        guard let dependency = field.dependsOn else { return true }
        
        guard let dependentValue = state.values[dependency.field] else {
            return dependency.condition == .empty
        }
        
        switch dependency.condition {
        case .equals:
            return "\(dependentValue)" == "\(dependency.value?.value ?? "")"
        case .notEquals:
            return "\(dependentValue)" != "\(dependency.value?.value ?? "")"
        case .empty:
            return (dependentValue as? String)?.isEmpty ?? true
        case .notEmpty:
            return !((dependentValue as? String)?.isEmpty ?? true)
        default:
            return true
        }
    }
    
    @ViewBuilder
    private func fieldView(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            switch field.type {
            case .text, .email, .url:
                textField(for: field)
            case .password:
                passwordField(for: field)
            case .textarea:
                textAreaField(for: field)
            case .number, .currency:
                numberField(for: field)
            case .select:
                selectField(for: field)
            case .radio:
                radioField(for: field)
            case .checkbox, .toggle:
                toggleField(for: field)
            case .slider:
                sliderField(for: field)
            case .rating:
                ratingField(for: field)
            case .date:
                dateField(for: field)
            case .time:
                timeField(for: field)
            default:
                textField(for: field)
            }
            
            // Help text
            if let helpText = field.helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Error
            if let error = state.errors[field.id] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(theme.errorColor)
            }
        }
    }
    
    // MARK: - Field Builders
    
    private func textField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            TextField(
                field.placeholder ?? "",
                text: Binding(
                    get: { state.values[field.id] as? String ?? "" },
                    set: { state.values[field.id] = $0; validate(field) }
                )
            )
            .textFieldStyle(.roundedBorder)
            .keyboardType(keyboardType(for: field.type))
            .textContentType(contentType(for: field.type))
            .disabled(field.disabled)
        }
    }
    
    private func passwordField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            SecureField(
                field.placeholder ?? "",
                text: Binding(
                    get: { state.values[field.id] as? String ?? "" },
                    set: { state.values[field.id] = $0; validate(field) }
                )
            )
            .textFieldStyle(.roundedBorder)
            .textContentType(.password)
            .disabled(field.disabled)
        }
    }
    
    private func textAreaField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            TextEditor(text: Binding(
                get: { state.values[field.id] as? String ?? "" },
                set: { state.values[field.id] = $0; validate(field) }
            ))
            .frame(minHeight: 100)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
            .disabled(field.disabled)
        }
    }
    
    private func numberField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            TextField(
                field.placeholder ?? "",
                text: Binding(
                    get: {
                        if let value = state.values[field.id] as? Double {
                            return String(format: "%.2f", value)
                        }
                        return state.values[field.id] as? String ?? ""
                    },
                    set: {
                        state.values[field.id] = Double($0) ?? $0
                        validate(field)
                    }
                )
            )
            .textFieldStyle(.roundedBorder)
            .keyboardType(.decimalPad)
            .disabled(field.disabled)
        }
    }
    
    private func selectField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            Picker(
                "",
                selection: Binding(
                    get: { state.values[field.id] as? String ?? "" },
                    set: { state.values[field.id] = $0; validate(field) }
                )
            ) {
                Text("Select...").tag("")
                ForEach(field.options ?? []) { option in
                    Text(option.label).tag(option.id)
                }
            }
            .pickerStyle(.menu)
            .disabled(field.disabled)
        }
    }
    
    private func radioField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            ForEach(field.options ?? []) { option in
                Button(action: { state.values[field.id] = option.id; validate(field) }) {
                    HStack {
                        Image(systemName: (state.values[field.id] as? String) == option.id ? "circle.fill" : "circle")
                            .foregroundColor((state.values[field.id] as? String) == option.id ? theme.primaryColor : .secondary)
                        Text(option.label)
                            .foregroundColor(.primary)
                    }
                }
                .disabled(field.disabled || (option.disabled ?? false))
            }
        }
    }
    
    private func toggleField(for field: FieldSchema) -> some View {
        Toggle(
            field.label,
            isOn: Binding(
                get: { state.values[field.id] as? Bool ?? false },
                set: { state.values[field.id] = $0; validate(field) }
            )
        )
        .disabled(field.disabled)
    }
    
    private func sliderField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(field.label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.0f", state.values[field.id] as? Double ?? 0))
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { state.values[field.id] as? Double ?? 0 },
                    set: { state.values[field.id] = $0; validate(field) }
                ),
                in: (field.properties?["min"]?.doubleValue ?? 0)...(field.properties?["max"]?.doubleValue ?? 100)
            )
            .disabled(field.disabled)
        }
    }
    
    private func ratingField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: (state.values[field.id] as? Int ?? 0) >= star ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            state.values[field.id] = star
                            validate(field)
                        }
                }
            }
        }
    }
    
    private func dateField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            DatePicker(
                "",
                selection: Binding(
                    get: { state.values[field.id] as? Date ?? Date() },
                    set: { state.values[field.id] = $0; validate(field) }
                ),
                displayedComponents: .date
            )
            .labelsHidden()
            .disabled(field.disabled)
        }
    }
    
    private func timeField(for field: FieldSchema) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(field.label)
                .font(.subheadline.weight(.medium))
            
            DatePicker(
                "",
                selection: Binding(
                    get: { state.values[field.id] as? Date ?? Date() },
                    set: { state.values[field.id] = $0; validate(field) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .disabled(field.disabled)
        }
    }
    
    // MARK: - Helpers
    
    private func keyboardType(for type: FieldSchema.FieldType) -> UIKeyboardType {
        switch type {
        case .email: return .emailAddress
        case .phone: return .phonePad
        case .number, .currency: return .decimalPad
        case .url: return .URL
        default: return .default
        }
    }
    
    private func contentType(for type: FieldSchema.FieldType) -> UITextContentType? {
        switch type {
        case .email: return .emailAddress
        case .phone: return .telephoneNumber
        case .url: return .URL
        default: return nil
        }
    }
    
    private func validate(_ field: FieldSchema) {
        state.errors[field.id] = nil
        
        let value = state.values[field.id]
        
        // Required check
        if field.required {
            if value == nil || (value as? String)?.isEmpty == true {
                state.errors[field.id] = "\(field.label) is required"
                return
            }
        }
        
        // Validation rules
        guard let rules = field.validation else { return }
        
        for rule in rules {
            if let error = validateRule(rule, value: value, field: field) {
                state.errors[field.id] = error
                return
            }
        }
    }
    
    private func validateRule(_ rule: ValidationRuleSchema, value: Any?, field: FieldSchema) -> String? {
        let stringValue = value as? String ?? ""
        let message = rule.message
        
        switch rule.type {
        case .required:
            if stringValue.isEmpty {
                return message ?? "\(field.label) is required"
            }
        case .minLength:
            if let min = rule.value?.intValue, stringValue.count < min {
                return message ?? "\(field.label) must be at least \(min) characters"
            }
        case .maxLength:
            if let max = rule.value?.intValue, stringValue.count > max {
                return message ?? "\(field.label) must be at most \(max) characters"
            }
        case .email:
            let emailRegex = #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#
            if !stringValue.isEmpty && stringValue.range(of: emailRegex, options: .regularExpression) == nil {
                return message ?? "Please enter a valid email"
            }
        case .pattern:
            if let pattern = rule.value?.stringValue {
                if stringValue.range(of: pattern, options: .regularExpression) == nil {
                    return message ?? "Invalid format"
                }
            }
        default:
            break
        }
        
        return nil
    }
    
    private func submit() {
        // Validate all fields
        for field in schema.fields {
            validate(field)
        }
        
        guard state.isValid else { return }
        onSubmit?(state.values)
    }
}

// MARK: - JSON Form State

/// Observable state for JSON-driven forms
public class JSONFormState: ObservableObject {
    @Published public var values: [String: Any] = [:]
    @Published public var errors: [String: String] = [:]
    @Published public var touched: Set<String> = []
    
    public var isValid: Bool {
        errors.isEmpty || errors.values.allSatisfy { $0.isEmpty }
    }
    
    public init(defaultValues: [String: Any] = [:]) {
        self.values = defaultValues
    }
    
    public func reset() {
        values.removeAll()
        errors.removeAll()
        touched.removeAll()
    }
    
    public func setValue(_ value: Any, for fieldId: String) {
        values[fieldId] = value
        touched.insert(fieldId)
    }
}

// MARK: - Preview

#Preview {
    let schema = FormSchema(
        id: "contact",
        title: "Contact Form",
        description: "Get in touch with us",
        fields: [
            FieldSchema(id: "name", type: .text, label: "Name", required: true),
            FieldSchema(id: "email", type: .email, label: "Email", required: true, validation: [
                ValidationRuleSchema(type: .email)
            ]),
            FieldSchema(id: "message", type: .textarea, label: "Message", helpText: "Tell us what's on your mind"),
            FieldSchema(id: "rating", type: .rating, label: "How would you rate us?")
        ]
    )
    
    return JSONFormView(schema: schema, state: JSONFormState())
}
