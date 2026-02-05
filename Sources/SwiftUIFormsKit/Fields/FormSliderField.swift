import SwiftUI

// MARK: - Slider Style

/// Visual style for slider
public enum FormSliderStyle {
    case standard
    case labeled
    case stepped
    case range
    case gradient
}

// MARK: - Slider Field

/// Customizable slider with labels and stepped values
public struct FormSliderField: View {
    @Binding private var value: Double
    
    private let label: String
    private let range: ClosedRange<Double>
    private let step: Double?
    private let style: FormSliderStyle
    private let showValue: Bool
    private let valueFormat: String
    private let minLabel: String?
    private let maxLabel: String?
    private let marks: [Double]?
    private let gradientColors: [Color]
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...100,
        step: Double? = nil,
        style: FormSliderStyle = .standard,
        showValue: Bool = true,
        valueFormat: String = "%.0f",
        minLabel: String? = nil,
        maxLabel: String? = nil,
        marks: [Double]? = nil,
        gradientColors: [Color] = [.blue, .purple]
    ) {
        self.label = label
        self._value = value
        self.range = range
        self.step = step
        self.style = style
        self.showValue = showValue
        self.valueFormat = valueFormat
        self.minLabel = minLabel
        self.maxLabel = maxLabel
        self.marks = marks
        self.gradientColors = gradientColors
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
                
                if showValue {
                    Text(String(format: valueFormat, value))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(theme.primaryColor)
                        .fontWeight(.semibold)
                }
            }
            
            // Slider based on style
            switch style {
            case .standard:
                standardSlider
            case .labeled:
                labeledSlider
            case .stepped:
                steppedSlider
            case .range:
                rangeSlider
            case .gradient:
                gradientSlider
            }
        }
    }
    
    // MARK: - Standard Slider
    
    private var standardSlider: some View {
        Group {
            if let step = step {
                Slider(value: $value, in: range, step: step)
                    .tint(theme.primaryColor)
            } else {
                Slider(value: $value, in: range)
                    .tint(theme.primaryColor)
            }
        }
    }
    
    // MARK: - Labeled Slider
    
    private var labeledSlider: some View {
        VStack(spacing: 4) {
            Group {
                if let step = step {
                    Slider(value: $value, in: range, step: step)
                        .tint(theme.primaryColor)
                } else {
                    Slider(value: $value, in: range)
                        .tint(theme.primaryColor)
                }
            }
            
            HStack {
                Text(minLabel ?? String(format: valueFormat, range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(maxLabel ?? String(format: valueFormat, range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Stepped Slider
    
    private var steppedSlider: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.primaryColor)
                        .frame(width: progressWidth(for: geometry.size.width), height: 4)
                    
                    // Marks
                    if let marks = marks {
                        ForEach(marks, id: \.self) { mark in
                            let position = (mark - range.lowerBound) / (range.upperBound - range.lowerBound)
                            Circle()
                                .fill(mark <= value ? theme.primaryColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .offset(x: geometry.size.width * CGFloat(position) - 4)
                        }
                    }
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: progressWidth(for: geometry.size.width) - 12)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    updateValue(from: gesture.location.x, in: geometry.size.width)
                                }
                        )
                }
            }
            .frame(height: 24)
            
            // Mark labels
            if let marks = marks {
                HStack {
                    ForEach(marks.indices, id: \.self) { index in
                        if index > 0 { Spacer() }
                        Text(String(format: valueFormat, marks[index]))
                            .font(.caption2)
                            .foregroundColor(marks[index] <= value ? theme.primaryColor : .secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Range Slider
    
    private var rangeSlider: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.primaryColor)
                        .frame(width: progressWidth(for: geometry.size.width), height: 8)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .overlay(
                            Text(String(format: "%.0f", value))
                                .font(.caption2.bold())
                                .foregroundColor(theme.primaryColor)
                        )
                        .offset(x: progressWidth(for: geometry.size.width) - 14)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    updateValue(from: gesture.location.x, in: geometry.size.width)
                                }
                        )
                }
            }
            .frame(height: 28)
            
            // Labels
            HStack {
                Text(minLabel ?? String(format: valueFormat, range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(maxLabel ?? String(format: valueFormat, range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Gradient Slider
    
    private var gradientSlider: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Gradient track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: gradientColors),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                    
                    // Thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 2)
                        .offset(x: progressWidth(for: geometry.size.width) - 12)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    updateValue(from: gesture.location.x, in: geometry.size.width)
                                }
                        )
                }
            }
            .frame(height: 24)
            
            // Labels
            HStack {
                Text(minLabel ?? String(format: valueFormat, range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(maxLabel ?? String(format: valueFormat, range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let normalizedValue = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * CGFloat(normalizedValue)
    }
    
    private func updateValue(from x: CGFloat, in width: CGFloat) {
        let normalizedX = max(0, min(width, x)) / width
        var newValue = range.lowerBound + Double(normalizedX) * (range.upperBound - range.lowerBound)
        
        // Snap to step if defined
        if let step = step {
            newValue = (newValue / step).rounded() * step
        }
        
        // Snap to marks if close
        if let marks = marks {
            for mark in marks {
                if abs(newValue - mark) < (range.upperBound - range.lowerBound) * 0.05 {
                    newValue = mark
                    break
                }
            }
        }
        
        value = max(range.lowerBound, min(range.upperBound, newValue))
    }
}

// MARK: - Double Thumb Range Slider

/// Range slider with two thumbs for min/max selection
public struct FormRangeSlider: View {
    @Binding private var lowerValue: Double
    @Binding private var upperValue: Double
    
    private let label: String
    private let range: ClosedRange<Double>
    private let step: Double?
    private let valueFormat: String
    
    @Environment(\.formTheme) private var theme
    @State private var draggedThumb: Thumb? = nil
    
    private enum Thumb {
        case lower, upper
    }
    
    public init(
        _ label: String,
        lowerValue: Binding<Double>,
        upperValue: Binding<Double>,
        range: ClosedRange<Double> = 0...100,
        step: Double? = nil,
        valueFormat: String = "%.0f"
    ) {
        self.label = label
        self._lowerValue = lowerValue
        self._upperValue = upperValue
        self.range = range
        self.step = step
        self.valueFormat = valueFormat
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
                
                Text("\(String(format: valueFormat, lowerValue)) - \(String(format: valueFormat, upperValue))")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(theme.primaryColor)
                    .fontWeight(.semibold)
            }
            
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    // Selected range
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.primaryColor)
                        .frame(width: rangeWidth(for: geometry.size.width), height: 8)
                        .offset(x: lowerPosition(for: geometry.size.width))
                    
                    // Lower thumb
                    thumb(value: lowerValue, in: geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = valueFromPosition(gesture.location.x, in: geometry.size.width)
                                    lowerValue = min(newValue, upperValue - (step ?? 1))
                                }
                        )
                    
                    // Upper thumb
                    thumb(value: upperValue, in: geometry.size.width)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    let newValue = valueFromPosition(gesture.location.x, in: geometry.size.width)
                                    upperValue = max(newValue, lowerValue + (step ?? 1))
                                }
                        )
                }
            }
            .frame(height: 28)
            
            // Labels
            HStack {
                Text(String(format: valueFormat, range.lowerBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: valueFormat, range.upperBound))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func thumb(value: Double, in width: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 28, height: 28)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .offset(x: position(for: value, in: width) - 14)
    }
    
    private func position(for value: Double, in width: CGFloat) -> CGFloat {
        let normalized = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return width * CGFloat(normalized)
    }
    
    private func lowerPosition(for width: CGFloat) -> CGFloat {
        position(for: lowerValue, in: width)
    }
    
    private func rangeWidth(for width: CGFloat) -> CGFloat {
        position(for: upperValue, in: width) - lowerPosition(for: width)
    }
    
    private func valueFromPosition(_ x: CGFloat, in width: CGFloat) -> Double {
        let normalized = max(0, min(1, Double(x / width)))
        var value = range.lowerBound + normalized * (range.upperBound - range.lowerBound)
        
        if let step = step {
            value = (value / step).rounded() * step
        }
        
        return max(range.lowerBound, min(range.upperBound, value))
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            FormSliderField("Volume", value: .constant(50))
            
            FormSliderField(
                "Brightness",
                value: .constant(75),
                style: .labeled,
                minLabel: "Dark",
                maxLabel: "Bright"
            )
            
            FormSliderField(
                "Quality",
                value: .constant(3),
                range: 1...5,
                step: 1,
                style: .stepped,
                marks: [1, 2, 3, 4, 5]
            )
            
            FormSliderField(
                "Temperature",
                value: .constant(22),
                range: 16...30,
                style: .gradient,
                valueFormat: "%.0f°C",
                gradientColors: [.blue, .orange, .red]
            )
            
            FormRangeSlider(
                "Price Range",
                lowerValue: .constant(20),
                upperValue: .constant(80),
                valueFormat: "$%.0f"
            )
        }
        .padding()
    }
}
