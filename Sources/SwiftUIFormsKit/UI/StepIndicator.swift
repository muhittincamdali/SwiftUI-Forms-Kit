import SwiftUI

// MARK: - Step Indicator Configuration

/// Configuration for step indicator appearance and behavior
public struct StepIndicatorConfiguration {
    public var style: StepIndicatorStyle
    public var size: StepIndicatorSize
    public var orientation: StepIndicatorOrientation
    public var showLabels: Bool
    public var showNumbers: Bool
    public var showConnectors: Bool
    public var animateTransitions: Bool
    public var tapToNavigate: Bool
    
    public init(
        style: StepIndicatorStyle = .filled,
        size: StepIndicatorSize = .medium,
        orientation: StepIndicatorOrientation = .horizontal,
        showLabels: Bool = true,
        showNumbers: Bool = true,
        showConnectors: Bool = true,
        animateTransitions: Bool = true,
        tapToNavigate: Bool = true
    ) {
        self.style = style
        self.size = size
        self.orientation = orientation
        self.showLabels = showLabels
        self.showNumbers = showNumbers
        self.showConnectors = showConnectors
        self.animateTransitions = animateTransitions
        self.tapToNavigate = tapToNavigate
    }
    
    public static let `default` = StepIndicatorConfiguration()
    public static let minimal = StepIndicatorConfiguration(
        style: .dots,
        size: .small,
        showLabels: false,
        showNumbers: false
    )
    public static let detailed = StepIndicatorConfiguration(
        style: .filled,
        size: .large,
        showLabels: true,
        showNumbers: true,
        showConnectors: true
    )
}

/// Visual style for step indicators
public enum StepIndicatorStyle {
    case filled       // Solid filled circles
    case outlined     // Outlined circles
    case dots         // Simple dots
    case numbered     // Numbers only
    case icons        // Custom icons
    case progress     // Progress bar style
    case timeline     // Timeline style
}

/// Size options for step indicators
public enum StepIndicatorSize {
    case small
    case medium
    case large
    case custom(CGFloat)
    
    var value: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 44
        case .custom(let size): return size
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small: return .caption2
        case .medium: return .caption
        case .large: return .body
        case .custom(let size):
            if size < 28 { return .caption2 }
            if size < 36 { return .caption }
            return .body
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        case .custom(let size): return size * 0.5
        }
    }
}

/// Orientation for step indicator layout
public enum StepIndicatorOrientation {
    case horizontal
    case vertical
}

// MARK: - Step Model

/// Represents a single step in the indicator
public struct StepItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let icon: String?
    public let status: StepStatus
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        status: StepStatus = .pending
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.status = status
    }
}

/// Status of a step
public enum StepStatus: Equatable {
    case pending      // Not yet reached
    case current      // Currently active
    case completed    // Successfully completed
    case error        // Completed with error
    case skipped      // Skipped (optional step)
    
    public var color: Color {
        switch self {
        case .pending: return Color(.systemGray4)
        case .current: return .accentColor
        case .completed: return .green
        case .error: return .red
        case .skipped: return .orange
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "circle"
        case .current: return "circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .skipped: return "arrow.right.circle.fill"
        }
    }
}

// MARK: - Step Indicator View

/// A customizable step indicator component
public struct StepIndicator: View {
    private let steps: [StepItem]
    private let configuration: StepIndicatorConfiguration
    private let onStepTapped: ((Int) -> Void)?
    
    @State private var hoveredStep: Int?
    
    public init(
        steps: [StepItem],
        configuration: StepIndicatorConfiguration = .default,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        self.steps = steps
        self.configuration = configuration
        self.onStepTapped = onStepTapped
    }
    
    public var body: some View {
        Group {
            switch configuration.orientation {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            }
        }
    }
    
    // MARK: - Horizontal Layout
    
    private var horizontalLayout: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepView(for: step, at: index)
                
                if index < steps.count - 1 && configuration.showConnectors {
                    connectorView(from: step.status, to: steps[index + 1].status)
                }
            }
        }
    }
    
    // MARK: - Vertical Layout
    
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        stepCircle(for: step, at: index)
                        
                        if index < steps.count - 1 && configuration.showConnectors {
                            verticalConnector(from: step.status, to: steps[index + 1].status)
                        }
                    }
                    
                    if configuration.showLabels {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(configuration.size.fontSize)
                                .fontWeight(step.status == .current ? .semibold : .regular)
                                .foregroundColor(step.status == .current ? .primary : .secondary)
                            
                            if let subtitle = step.subtitle {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.bottom, index < steps.count - 1 ? 24 : 0)
                    }
                }
            }
        }
    }
    
    // MARK: - Step View
    
    private func stepView(for step: StepItem, at index: Int) -> some View {
        VStack(spacing: 8) {
            stepCircle(for: step, at: index)
            
            if configuration.showLabels {
                VStack(spacing: 2) {
                    Text(step.title)
                        .font(configuration.size.fontSize)
                        .fontWeight(step.status == .current ? .semibold : .regular)
                        .foregroundColor(step.status == .current ? .primary : .secondary)
                        .lineLimit(1)
                    
                    if let subtitle = step.subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(minWidth: configuration.size.value + 20)
    }
    
    // MARK: - Step Circle
    
    private func stepCircle(for step: StepItem, at index: Int) -> some View {
        let isInteractive = configuration.tapToNavigate && onStepTapped != nil
        
        return Button {
            if isInteractive {
                onStepTapped?(index)
            }
        } label: {
            ZStack {
                switch configuration.style {
                case .filled:
                    filledCircle(for: step, at: index)
                case .outlined:
                    outlinedCircle(for: step, at: index)
                case .dots:
                    dotIndicator(for: step)
                case .numbered:
                    numberedIndicator(for: step, at: index)
                case .icons:
                    iconIndicator(for: step, at: index)
                case .progress:
                    progressIndicator(for: step, at: index)
                case .timeline:
                    timelineIndicator(for: step, at: index)
                }
            }
            .animation(
                configuration.animateTransitions ? .spring(response: 0.3) : nil,
                value: step.status
            )
        }
        .buttonStyle(.plain)
        .disabled(!isInteractive)
    }
    
    // MARK: - Circle Styles
    
    private func filledCircle(for step: StepItem, at index: Int) -> some View {
        ZStack {
            Circle()
                .fill(step.status.color)
                .frame(width: configuration.size.value, height: configuration.size.value)
            
            circleContent(for: step, at: index)
        }
    }
    
    private func outlinedCircle(for step: StepItem, at index: Int) -> some View {
        ZStack {
            Circle()
                .stroke(step.status.color, lineWidth: 2)
                .background(
                    Circle()
                        .fill(step.status == .current ? step.status.color.opacity(0.1) : Color.clear)
                )
                .frame(width: configuration.size.value, height: configuration.size.value)
            
            circleContent(for: step, at: index, useStatusColor: true)
        }
    }
    
    private func dotIndicator(for step: StepItem) -> some View {
        Circle()
            .fill(step.status.color)
            .frame(
                width: step.status == .current ? configuration.size.value * 0.5 : configuration.size.value * 0.35,
                height: step.status == .current ? configuration.size.value * 0.5 : configuration.size.value * 0.35
            )
    }
    
    private func numberedIndicator(for step: StepItem, at index: Int) -> some View {
        Text("\(index + 1)")
            .font(configuration.size.fontSize.bold())
            .foregroundColor(step.status == .current ? .accentColor : .secondary)
    }
    
    private func iconIndicator(for step: StepItem, at index: Int) -> some View {
        ZStack {
            Circle()
                .fill(step.status.color)
                .frame(width: configuration.size.value, height: configuration.size.value)
            
            if let icon = step.icon {
                Image(systemName: icon)
                    .font(.system(size: configuration.size.iconSize))
                    .foregroundColor(.white)
            } else {
                circleContent(for: step, at: index)
            }
        }
    }
    
    private func progressIndicator(for step: StepItem, at index: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 3)
                .frame(width: configuration.size.value, height: configuration.size.value)
            
            Circle()
                .trim(from: 0, to: progressValue(for: step.status))
                .stroke(step.status.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: configuration.size.value, height: configuration.size.value)
                .rotationEffect(.degrees(-90))
            
            circleContent(for: step, at: index, useStatusColor: true)
        }
    }
    
    private func timelineIndicator(for step: StepItem, at index: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(step.status == .current ? step.status.color : Color(.systemGray5))
                    .frame(width: configuration.size.value * 0.4, height: configuration.size.value * 0.4)
                
                if step.status == .completed {
                    Image(systemName: "checkmark")
                        .font(.system(size: configuration.size.iconSize * 0.6, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Circle Content
    
    private func circleContent(for step: StepItem, at index: Int, useStatusColor: Bool = false) -> some View {
        Group {
            if step.status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: configuration.size.iconSize, weight: .bold))
                    .foregroundColor(useStatusColor ? step.status.color : .white)
            } else if step.status == .error {
                Image(systemName: "xmark")
                    .font(.system(size: configuration.size.iconSize, weight: .bold))
                    .foregroundColor(useStatusColor ? step.status.color : .white)
            } else if step.status == .skipped {
                Image(systemName: "arrow.right")
                    .font(.system(size: configuration.size.iconSize, weight: .bold))
                    .foregroundColor(useStatusColor ? step.status.color : .white)
            } else if configuration.showNumbers {
                Text("\(index + 1)")
                    .font(configuration.size.fontSize.bold())
                    .foregroundColor(useStatusColor ? step.status.color : (step.status == .current ? .white : .secondary))
            }
        }
    }
    
    // MARK: - Connectors
    
    private func connectorView(from: StepStatus, to: StepStatus) -> some View {
        let color: Color = from == .completed ? .green : Color(.systemGray4)
        
        return Rectangle()
            .fill(color)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -4)
    }
    
    private func verticalConnector(from: StepStatus, to: StepStatus) -> some View {
        let color: Color = from == .completed ? .green : Color(.systemGray4)
        
        return Rectangle()
            .fill(color)
            .frame(width: 2, height: 24)
    }
    
    // MARK: - Helpers
    
    private func progressValue(for status: StepStatus) -> CGFloat {
        switch status {
        case .pending: return 0
        case .current: return 0.5
        case .completed, .error, .skipped: return 1
        }
    }
}

// MARK: - Convenience Initializers

extension StepIndicator {
    /// Creates a step indicator from step titles and current index
    public init(
        titles: [String],
        currentIndex: Int,
        configuration: StepIndicatorConfiguration = .default,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        let steps = titles.enumerated().map { index, title in
            StepItem(
                title: title,
                status: index < currentIndex ? .completed : (index == currentIndex ? .current : .pending)
            )
        }
        self.init(steps: steps, configuration: configuration, onStepTapped: onStepTapped)
    }
    
    /// Creates a step indicator with completed steps set
    public init(
        titles: [String],
        currentIndex: Int,
        completedIndices: Set<Int>,
        configuration: StepIndicatorConfiguration = .default,
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        let steps = titles.enumerated().map { index, title in
            let status: StepStatus
            if index == currentIndex {
                status = .current
            } else if completedIndices.contains(index) {
                status = .completed
            } else {
                status = .pending
            }
            return StepItem(title: title, status: status)
        }
        self.init(steps: steps, configuration: configuration, onStepTapped: onStepTapped)
    }
}

// MARK: - Progress Bar Step Indicator

/// A linear progress bar style step indicator
public struct ProgressBarStepIndicator: View {
    private let totalSteps: Int
    private let currentStep: Int
    private let completedColor: Color
    private let pendingColor: Color
    private let height: CGFloat
    private let showLabels: Bool
    private let labels: [String]
    
    public init(
        totalSteps: Int,
        currentStep: Int,
        completedColor: Color = .accentColor,
        pendingColor: Color = Color(.systemGray5),
        height: CGFloat = 4,
        showLabels: Bool = false,
        labels: [String] = []
    ) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.completedColor = completedColor
        self.pendingColor = pendingColor
        self.height = height
        self.showLabels = showLabels
        self.labels = labels
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(pendingColor)
                        .frame(height: height)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(completedColor)
                        .frame(width: progressWidth(in: geometry.size.width), height: height)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .frame(height: height)
            
            if showLabels && !labels.isEmpty {
                HStack {
                    ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard totalSteps > 1 else { return totalWidth }
        let stepWidth = totalWidth / CGFloat(totalSteps - 1)
        return stepWidth * CGFloat(currentStep)
    }
}

// MARK: - Segmented Step Indicator

/// A segmented style step indicator
public struct SegmentedStepIndicator: View {
    private let totalSteps: Int
    private let currentStep: Int
    private let completedColor: Color
    private let currentColor: Color
    private let pendingColor: Color
    private let spacing: CGFloat
    private let height: CGFloat
    
    public init(
        totalSteps: Int,
        currentStep: Int,
        completedColor: Color = .green,
        currentColor: Color = .accentColor,
        pendingColor: Color = Color(.systemGray5),
        spacing: CGFloat = 4,
        height: CGFloat = 4
    ) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.completedColor = completedColor
        self.currentColor = currentColor
        self.pendingColor = pendingColor
        self.spacing = spacing
        self.height = height
    }
    
    public var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(colorForStep(index))
                    .frame(height: height)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
    }
    
    private func colorForStep(_ index: Int) -> Color {
        if index < currentStep {
            return completedColor
        } else if index == currentStep {
            return currentColor
        } else {
            return pendingColor
        }
    }
}

// MARK: - Circular Progress Step Indicator

/// A circular progress step indicator
public struct CircularStepIndicator: View {
    private let totalSteps: Int
    private let currentStep: Int
    private let size: CGFloat
    private let lineWidth: CGFloat
    private let completedColor: Color
    private let pendingColor: Color
    private let showLabel: Bool
    
    public init(
        totalSteps: Int,
        currentStep: Int,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        completedColor: Color = .accentColor,
        pendingColor: Color = Color(.systemGray5),
        showLabel: Bool = true
    ) {
        self.totalSteps = totalSteps
        self.currentStep = currentStep
        self.size = size
        self.lineWidth = lineWidth
        self.completedColor = completedColor
        self.pendingColor = pendingColor
        self.showLabel = showLabel
    }
    
    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(pendingColor, lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(completedColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: currentStep)
            
            // Label
            if showLabel {
                VStack(spacing: 0) {
                    Text("\(currentStep + 1)")
                        .font(.system(size: size * 0.3, weight: .bold))
                    Text("of \(totalSteps)")
                        .font(.system(size: size * 0.15))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var progress: CGFloat {
        guard totalSteps > 0 else { return 0 }
        return CGFloat(currentStep + 1) / CGFloat(totalSteps)
    }
}

// MARK: - Breadcrumb Step Indicator

/// A breadcrumb style step indicator
public struct BreadcrumbStepIndicator: View {
    private let steps: [String]
    private let currentIndex: Int
    private let separator: String
    private let onStepTapped: ((Int) -> Void)?
    
    public init(
        steps: [String],
        currentIndex: Int,
        separator: String = ">",
        onStepTapped: ((Int) -> Void)? = nil
    ) {
        self.steps = steps
        self.currentIndex = currentIndex
        self.separator = separator
        self.onStepTapped = onStepTapped
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    if index > 0 {
                        Text(separator)
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        onStepTapped?(index)
                    } label: {
                        Text(step)
                            .font(index == currentIndex ? .body.bold() : .body)
                            .foregroundColor(stepColor(for: index))
                    }
                    .buttonStyle(.plain)
                    .disabled(onStepTapped == nil)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < currentIndex {
            return .accentColor
        } else if index == currentIndex {
            return .primary
        } else {
            return .secondary
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StepIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Default style
                GroupBox("Default") {
                    StepIndicator(
                        titles: ["Account", "Profile", "Preferences", "Review"],
                        currentIndex: 1
                    )
                }
                
                // Minimal style
                GroupBox("Minimal") {
                    StepIndicator(
                        titles: ["1", "2", "3", "4"],
                        currentIndex: 2,
                        configuration: .minimal
                    )
                }
                
                // Vertical style
                GroupBox("Vertical") {
                    StepIndicator(
                        steps: [
                            StepItem(title: "Sign Up", subtitle: "Create account", status: .completed),
                            StepItem(title: "Verify Email", subtitle: "Check inbox", status: .current),
                            StepItem(title: "Complete Profile", subtitle: "Add details", status: .pending)
                        ],
                        configuration: StepIndicatorConfiguration(orientation: .vertical)
                    )
                }
                
                // Progress bar
                GroupBox("Progress Bar") {
                    ProgressBarStepIndicator(
                        totalSteps: 5,
                        currentStep: 2,
                        showLabels: true,
                        labels: ["Start", "Info", "Payment", "Confirm", "Done"]
                    )
                }
                
                // Segmented
                GroupBox("Segmented") {
                    SegmentedStepIndicator(totalSteps: 4, currentStep: 1)
                }
                
                // Circular
                GroupBox("Circular") {
                    CircularStepIndicator(totalSteps: 5, currentStep: 2)
                }
                
                // Breadcrumb
                GroupBox("Breadcrumb") {
                    BreadcrumbStepIndicator(
                        steps: ["Home", "Products", "Electronics", "Phones"],
                        currentIndex: 2
                    )
                }
            }
            .padding()
        }
    }
}
#endif