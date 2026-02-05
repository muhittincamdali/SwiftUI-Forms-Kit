import SwiftUI

// MARK: - Rating Style

/// Visual style for rating input
public enum RatingStyle {
    case stars
    case hearts
    case circles
    case emoji
    case custom(filled: String, empty: String)
    
    var filledSymbol: String {
        switch self {
        case .stars: return "star.fill"
        case .hearts: return "heart.fill"
        case .circles: return "circle.fill"
        case .emoji: return "😀"
        case .custom(let filled, _): return filled
        }
    }
    
    var emptySymbol: String {
        switch self {
        case .stars: return "star"
        case .hearts: return "heart"
        case .circles: return "circle"
        case .emoji: return "😐"
        case .custom(_, let empty): return empty
        }
    }
    
    var isSystemImage: Bool {
        switch self {
        case .emoji: return false
        case .custom(let filled, _): return !filled.contains(".")
        default: return true
        }
    }
}

// MARK: - Rating Field

/// Interactive rating input with customizable symbols
public struct FormRatingField: View {
    @Binding private var rating: Int
    
    private let label: String
    private let maxRating: Int
    private let style: RatingStyle
    private let size: CGFloat
    private let spacing: CGFloat
    private let filledColor: Color
    private let emptyColor: Color
    private let showLabels: Bool
    private let labels: [String]?
    private let allowHalfRating: Bool
    private let hapticFeedback: Bool
    
    @State private var hoverRating: Int? = nil
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String = "",
        rating: Binding<Int>,
        maxRating: Int = 5,
        style: RatingStyle = .stars,
        size: CGFloat = 28,
        spacing: CGFloat = 4,
        filledColor: Color = .yellow,
        emptyColor: Color = .gray.opacity(0.3),
        showLabels: Bool = false,
        labels: [String]? = nil,
        allowHalfRating: Bool = false,
        hapticFeedback: Bool = true
    ) {
        self.label = label
        self._rating = rating
        self.maxRating = maxRating
        self.style = style
        self.size = size
        self.spacing = spacing
        self.filledColor = filledColor
        self.emptyColor = emptyColor
        self.showLabels = showLabels
        self.labels = labels
        self.allowHalfRating = allowHalfRating
        self.hapticFeedback = hapticFeedback
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            if !label.isEmpty {
                HStack {
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(theme.labelColor)
                    
                    Spacer()
                    
                    // Current rating text
                    Text("\(rating)/\(maxRating)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Rating symbols
            HStack(spacing: spacing) {
                ForEach(1...maxRating, id: \.self) { index in
                    ratingSymbol(for: index)
                        .onTapGesture {
                            setRating(index)
                        }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label) rating")
            .accessibilityValue("\(rating) out of \(maxRating)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    if rating < maxRating { rating += 1 }
                case .decrement:
                    if rating > 0 { rating -= 1 }
                @unknown default:
                    break
                }
            }
            
            // Label text
            if showLabels, let labelText = currentLabel {
                Text(labelText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: rating)
            }
        }
    }
    
    // MARK: - Rating Symbol
    
    @ViewBuilder
    private func ratingSymbol(for index: Int) -> some View {
        let isFilled = index <= (hoverRating ?? rating)
        
        Group {
            if style.isSystemImage {
                Image(systemName: isFilled ? style.filledSymbol : style.emptySymbol)
                    .font(.system(size: size))
                    .foregroundColor(isFilled ? filledColor : emptyColor)
            } else {
                Text(isFilled ? style.filledSymbol : style.emptySymbol)
                    .font(.system(size: size))
            }
        }
        .scaleEffect(hoverRating == index ? 1.2 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hoverRating)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
    }
    
    // MARK: - Helpers
    
    private var currentLabel: String? {
        guard let labels = labels, rating > 0, rating <= labels.count else {
            return defaultLabel
        }
        return labels[rating - 1]
    }
    
    private var defaultLabel: String? {
        guard showLabels, rating > 0 else { return nil }
        let defaultLabels = ["Poor", "Fair", "Good", "Very Good", "Excellent"]
        if rating <= defaultLabels.count && maxRating == 5 {
            return defaultLabels[rating - 1]
        }
        return nil
    }
    
    private func setRating(_ newRating: Int) {
        // Tap same rating to clear
        if rating == newRating {
            rating = 0
        } else {
            rating = newRating
        }
        
        if hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
}

// MARK: - Emoji Rating

/// Quick emoji-based rating (thumb up/down, face scale)
public struct FormEmojiRating: View {
    @Binding private var rating: Int
    
    private let label: String
    private let emojis: [String]
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String = "",
        rating: Binding<Int>,
        emojis: [String] = ["😞", "😕", "😐", "🙂", "😀"]
    ) {
        self.label = label
        self._rating = rating
        self.emojis = emojis
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
            }
            
            HStack(spacing: 12) {
                ForEach(0..<emojis.count, id: \.self) { index in
                    Text(emojis[index])
                        .font(.system(size: rating == index + 1 ? 40 : 30))
                        .opacity(rating == 0 || rating == index + 1 ? 1 : 0.4)
                        .scaleEffect(rating == index + 1 ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3), value: rating)
                        .onTapGesture {
                            if rating == index + 1 {
                                rating = 0
                            } else {
                                rating = index + 1
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }
                        }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(rating > 0 ? emojis[rating - 1] : "No rating")
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        FormRatingField("Rate this app", rating: .constant(4))
        
        FormRatingField(
            "Love it?",
            rating: .constant(3),
            style: .hearts,
            filledColor: .red
        )
        
        FormRatingField(
            "Quality",
            rating: .constant(4),
            showLabels: true
        )
        
        FormEmojiRating("How was your experience?", rating: .constant(4))
    }
    .padding()
}
