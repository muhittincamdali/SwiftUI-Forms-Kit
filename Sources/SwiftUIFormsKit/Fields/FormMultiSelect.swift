import SwiftUI

// MARK: - Multi Select Style

/// Display style for multi-selection field
public enum MultiSelectStyle {
    case chips
    case list
    case sheet
    case inline
}

// MARK: - Selectable Option

/// Protocol for selectable options
public protocol SelectableOption: Identifiable, Hashable {
    var displayName: String { get }
    var icon: String? { get }
}

/// Default implementation
public extension SelectableOption {
    var icon: String? { nil }
}

/// Simple string-based option
public struct StringOption: SelectableOption {
    public let id: String
    public let displayName: String
    public let icon: String?
    
    public init(_ value: String, icon: String? = nil) {
        self.id = value
        self.displayName = value
        self.icon = icon
    }
}

// MARK: - Multi Select Field

/// Multi-selection input with various display styles
public struct FormMultiSelect<Option: SelectableOption>: View {
    @Binding private var selection: Set<Option.ID>
    
    private let label: String
    private let options: [Option]
    private let style: MultiSelectStyle
    private let minSelection: Int
    private let maxSelection: Int?
    private let placeholder: String
    
    @State private var isShowingSheet = false
    @State private var searchText = ""
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        selection: Binding<Set<Option.ID>>,
        options: [Option],
        style: MultiSelectStyle = .chips,
        minSelection: Int = 0,
        maxSelection: Int? = nil,
        placeholder: String = "Select options"
    ) {
        self.label = label
        self._selection = selection
        self.options = options
        self.style = style
        self.minSelection = minSelection
        self.maxSelection = maxSelection
        self.placeholder = placeholder
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label with count
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
                
                Spacer()
                
                if !selection.isEmpty {
                    Text("\(selection.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Content based on style
            switch style {
            case .chips:
                chipsView
            case .list:
                listView
            case .sheet:
                sheetTriggerView
            case .inline:
                inlineView
            }
            
            // Validation hint
            if let max = maxSelection, selection.count > max {
                Text("Maximum \(max) selections allowed")
                    .font(.caption)
                    .foregroundColor(theme.errorColor)
            } else if selection.count < minSelection {
                Text("Select at least \(minSelection)")
                    .font(.caption)
                    .foregroundColor(theme.errorColor)
            }
        }
        .sheet(isPresented: $isShowingSheet) {
            multiSelectSheet
        }
    }
    
    // MARK: - Chips View
    
    private var chipsView: some View {
        FlowLayout(spacing: 8) {
            ForEach(options) { option in
                ChipView(
                    option: option,
                    isSelected: selection.contains(option.id),
                    primaryColor: theme.primaryColor
                ) {
                    toggleSelection(option)
                }
            }
        }
    }
    
    // MARK: - List View
    
    private var listView: some View {
        VStack(spacing: 0) {
            ForEach(options) { option in
                listRow(for: option)
                if option.id != options.last?.id {
                    Divider()
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(theme.borderColor, lineWidth: 1)
        )
    }
    
    private func listRow(for option: Option) -> some View {
        Button(action: { toggleSelection(option) }) {
            HStack {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .foregroundColor(theme.primaryColor)
                }
                Text(option.displayName)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: selection.contains(option.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selection.contains(option.id) ? theme.primaryColor : .gray.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Sheet Trigger View
    
    private var sheetTriggerView: some View {
        Button(action: { isShowingSheet = true }) {
            HStack {
                if selection.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                } else {
                    Text(selectedOptionsText)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(theme.borderColor, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Inline View
    
    private var inlineView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(options) { option in
                Button(action: { toggleSelection(option) }) {
                    HStack {
                        Image(systemName: selection.contains(option.id) ? "checkmark.square.fill" : "square")
                            .foregroundColor(selection.contains(option.id) ? theme.primaryColor : .gray)
                        if let icon = option.icon {
                            Image(systemName: icon)
                                .foregroundColor(.secondary)
                        }
                        Text(option.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Sheet
    
    private var multiSelectSheet: some View {
        NavigationStack {
            List {
                ForEach(filteredOptions) { option in
                    Button(action: { toggleSelection(option) }) {
                        HStack {
                            if let icon = option.icon {
                                Image(systemName: icon)
                                    .foregroundColor(theme.primaryColor)
                            }
                            Text(option.displayName)
                                .foregroundColor(.primary)
                            Spacer()
                            if selection.contains(option.id) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search")
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        selection.removeAll()
                    }
                    .disabled(selection.isEmpty)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isShowingSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var filteredOptions: [Option] {
        if searchText.isEmpty {
            return options
        }
        return options.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var selectedOptionsText: String {
        let selected = options.filter { selection.contains($0.id) }
        return selected.map { $0.displayName }.joined(separator: ", ")
    }
    
    private func toggleSelection(_ option: Option) {
        if selection.contains(option.id) {
            if selection.count > minSelection {
                selection.remove(option.id)
            }
        } else {
            if let max = maxSelection, selection.count >= max {
                return
            }
            selection.insert(option.id)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Chip View

private struct ChipView<Option: SelectableOption>: View {
    let option: Option
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(option.displayName)
                    .font(.subheadline)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                Capsule()
                    .fill(isSelected ? primaryColor : Color.gray.opacity(0.15))
            )
        }
    }
}

// MARK: - Flow Layout

/// Wrapping horizontal layout for chips
public struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxX = max(maxX, currentX)
        }
        
        return (CGSize(width: maxX, height: currentY + lineHeight), positions)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var selection: Set<String> = []
        
        let options = [
            StringOption("Swift", icon: "swift"),
            StringOption("Python", icon: "chevron.left.forwardslash.chevron.right"),
            StringOption("JavaScript"),
            StringOption("TypeScript"),
            StringOption("Kotlin"),
            StringOption("Rust")
        ]
        
        var body: some View {
            ScrollView {
                VStack(spacing: 30) {
                    FormMultiSelect(
                        "Languages",
                        selection: $selection,
                        options: options,
                        style: .chips
                    )
                    
                    FormMultiSelect(
                        "Skills",
                        selection: $selection,
                        options: options,
                        style: .list
                    )
                }
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
