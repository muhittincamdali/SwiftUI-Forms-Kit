import SwiftUI

// MARK: - Signature Path

/// Stores drawing path data for the signature
public struct SignaturePath {
    public var points: [[CGPoint]]
    public var lineWidth: CGFloat
    public var lineColor: Color

    public init(
        points: [[CGPoint]] = [],
        lineWidth: CGFloat = 2.0,
        lineColor: Color = .primary
    ) {
        self.points = points
        self.lineWidth = lineWidth
        self.lineColor = lineColor
    }

    public var isEmpty: Bool {
        points.isEmpty || points.allSatisfy { $0.isEmpty }
    }
}

// MARK: - Signature Canvas

/// A canvas view for capturing freehand signatures
struct SignatureCanvas: View {
    @Binding var signaturePath: SignaturePath
    let backgroundColor: Color
    let borderColor: Color
    let cornerRadius: CGFloat

    @State private var currentLine: [CGPoint] = []

    var body: some View {
        Canvas { context, size in
            for line in signaturePath.points {
                guard line.count > 1 else { continue }
                var path = Path()
                path.move(to: line[0])
                for i in 1..<line.count {
                    path.addLine(to: line[i])
                }
                context.stroke(
                    path,
                    with: .color(signaturePath.lineColor),
                    lineWidth: signaturePath.lineWidth
                )
            }

            if currentLine.count > 1 {
                var path = Path()
                path.move(to: currentLine[0])
                for i in 1..<currentLine.count {
                    path.addLine(to: currentLine[i])
                }
                context.stroke(
                    path,
                    with: .color(signaturePath.lineColor),
                    lineWidth: signaturePath.lineWidth
                )
            }
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    currentLine.append(value.location)
                }
                .onEnded { _ in
                    signaturePath.points.append(currentLine)
                    currentLine = []
                }
        )
    }
}

// MARK: - Form Signature Field

/// A form field that captures hand-drawn signatures
public struct FormSignatureField: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let rules: [ValidationRule]
    public let canvasHeight: CGFloat
    public let lineWidth: CGFloat
    public let lineColor: Color

    @State private var signaturePath = SignaturePath()

    public init(
        key: String,
        title: String,
        rules: [ValidationRule] = [],
        canvasHeight: CGFloat = 150,
        lineWidth: CGFloat = 2.0,
        lineColor: Color = .primary
    ) {
        self.key = key
        self.title = title
        self.rules = rules
        self.canvasHeight = canvasHeight
        self.lineWidth = lineWidth
        self.lineColor = lineColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(theme.labelFont)
                    .foregroundColor(.primary)

                Spacer()

                Button("Clear") {
                    clearSignature()
                }
                .font(.caption)
                .foregroundColor(theme.primaryColor)
            }

            SignatureCanvas(
                signaturePath: $signaturePath,
                backgroundColor: theme.backgroundColor,
                borderColor: errorMessage != nil ? theme.errorColor : .gray.opacity(0.3),
                cornerRadius: theme.cornerRadius
            )
            .frame(height: canvasHeight)
            .onChange(of: signaturePath.points.count) { _ in
                formState.setValue(signaturePath, forKey: key)
                formState.touchField(key)
            }

            HStack {
                Image(systemName: "pencil.tip")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Draw your signature above")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
            }
        }
        .onAppear {
            signaturePath.lineWidth = lineWidth
            signaturePath.lineColor = lineColor
            formState.registerField(key, rules: rules)
        }
    }

    private func clearSignature() {
        signaturePath.points.removeAll()
        formState.setValue(nil, forKey: key)
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
