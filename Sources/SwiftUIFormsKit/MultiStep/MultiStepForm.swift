import SwiftUI

// MARK: - Step Indicator Style

/// Visual style for the step progress indicator
public enum StepIndicatorStyle {
    case numbered
    case dots
    case progress
    case icons
}

// MARK: - Multi Step Form

/// A wizard-style form that guides users through multiple steps
public struct MultiStepForm: View {
    @ObservedObject private var state: FormState
    private let theme: FormTheme
    private let steps: [FormStep]
    private let indicatorStyle: StepIndicatorStyle
    private let showNavigationButtons: Bool
    private let onComplete: (() -> Void)?

    @State private var currentStepIndex: Int = 0
    @State private var completedSteps: Set<Int> = []

    public init(
        state: FormState,
        theme: FormTheme = .default,
        indicatorStyle: StepIndicatorStyle = .numbered,
        showNavigationButtons: Bool = true,
        onComplete: (() -> Void)? = nil,
        @FormStepBuilder steps: () -> [FormStep]
    ) {
        self.state = state
        self.theme = theme
        self.indicatorStyle = indicatorStyle
        self.showNavigationButtons = showNavigationButtons
        self.onComplete = onComplete
        self.steps = steps()
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            stepIndicator
                .padding(.horizontal)
                .padding(.top, 16)

            // Step title
            VStack(spacing: 4) {
                Text(steps[currentStepIndex].title)
                    .font(.title2.bold())
                if let subtitle = steps[currentStepIndex].subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)

            // Step content
            TabView(selection: $currentStepIndex) {
                ForEach(0..<steps.count, id: \.self) { index in
                    ScrollView {
                        steps[index].content
                            .environment(\.formTheme, theme)
                            .environmentObject(state)
                            .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStepIndex)

            // Navigation buttons
            if showNavigationButtons {
                navigationButtons
                    .padding()
            }
        }
    }

    // MARK: - Step Indicator

    @ViewBuilder
    private var stepIndicator: some View {
        switch indicatorStyle {
        case .numbered:
            numberedIndicator
        case .dots:
            dotsIndicator
        case .progress:
            progressIndicator
        case .icons:
            iconsIndicator
        }
    }

    private var numberedIndicator: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 0) {
                    Circle()
                        .fill(circleColor(for: index))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Group {
                                if completedSteps.contains(index) {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundColor(index == currentStepIndex ? .white : .secondary)
                                }
                            }
                        )

                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(completedSteps.contains(index) ? theme.primaryColor : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
        }
    }

    private var dotsIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Circle()
                    .fill(index == currentStepIndex ? theme.primaryColor : Color.gray.opacity(0.3))
                    .frame(width: index == currentStepIndex ? 12 : 8, height: index == currentStepIndex ? 12 : 8)
                    .animation(.spring(response: 0.3), value: currentStepIndex)
            }
        }
    }

    private var progressIndicator: some View {
        VStack(spacing: 4) {
            ProgressView(value: Double(currentStepIndex + 1), total: Double(steps.count))
                .tint(theme.primaryColor)
            Text("Step \(currentStepIndex + 1) of \(steps.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var iconsIndicator: some View {
        HStack(spacing: 16) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 4) {
                    Image(systemName: steps[index].icon ?? "\(index + 1).circle")
                        .font(.title3)
                        .foregroundColor(index == currentStepIndex ? theme.primaryColor : .secondary)
                    Text(steps[index].title)
                        .font(.caption2)
                        .foregroundColor(index == currentStepIndex ? .primary : .secondary)
                }
            }
        }
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStepIndex > 0 {
                Button(action: goBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(theme.cornerRadius)
                }
            }

            Button(action: goForward) {
                HStack {
                    Text(isLastStep ? "Complete" : "Next")
                    if !isLastStep {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(theme.primaryColor)
                .cornerRadius(theme.cornerRadius)
            }
        }
    }

    private var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    private func goBack() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }

    private func goForward() {
        completedSteps.insert(currentStepIndex)

        if isLastStep {
            state.validateAll()
            if state.isValid {
                onComplete?()
            }
        } else {
            currentStepIndex += 1
        }
    }

    private func circleColor(for index: Int) -> Color {
        if completedSteps.contains(index) { return theme.primaryColor }
        if index == currentStepIndex { return theme.primaryColor }
        return Color.gray.opacity(0.3)
    }
}
