import SwiftUI
import PhotosUI

// MARK: - Form Photo Picker

/// A photo selection field that integrates with PhotosUI
public struct FormPhotoPicker: View {
    @EnvironmentObject private var formState: FormState
    @Environment(\.formTheme) private var theme

    public let key: String
    public let title: String
    public let rules: [ValidationRule]
    public let maxSelectionCount: Int
    public let selectionBehavior: PhotosPickerSelectionBehavior

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isLoading: Bool = false

    public init(
        key: String,
        title: String,
        rules: [ValidationRule] = [],
        maxSelectionCount: Int = 1,
        selectionBehavior: PhotosPickerSelectionBehavior = .default
    ) {
        self.key = key
        self.title = title
        self.rules = rules
        self.maxSelectionCount = maxSelectionCount
        self.selectionBehavior = selectionBehavior
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(theme.labelFont)
                .foregroundColor(.primary)

            if selectedImages.isEmpty {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: maxSelectionCount,
                    selectionBehavior: selectionBehavior,
                    matching: .images
                ) {
                    placeholderView
                }
            } else {
                VStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(0..<selectedImages.count, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        Button(action: { removeImage(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.white)
                                                .background(Circle().fill(.black.opacity(0.6)))
                                        }
                                        .offset(x: 4, y: -4),
                                        alignment: .topTrailing
                                    )
                            }

                            if selectedImages.count < maxSelectionCount {
                                PhotosPicker(
                                    selection: $selectedItems,
                                    maxSelectionCount: maxSelectionCount,
                                    selectionBehavior: selectionBehavior,
                                    matching: .images
                                ) {
                                    addMoreButton
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }

            if isLoading {
                ProgressView("Loading photos...")
                    .font(.caption)
            }

            if let error = errorMessage {
                Text(error)
                    .font(theme.errorFont)
                    .foregroundColor(theme.errorColor)
            }
        }
        .onAppear {
            formState.registerField(key, rules: rules)
        }
        .onChange(of: selectedItems) { newItems in
            loadImages(from: newItems)
        }
    }

    // MARK: - Subviews

    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Tap to select photos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(theme.backgroundColor)
        .cornerRadius(theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                .foregroundColor(.gray.opacity(0.4))
        )
    }

    private var addMoreButton: some View {
        VStack {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(theme.backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundColor(.gray.opacity(0.4))
        )
    }

    // MARK: - Helpers

    private func loadImages(from items: [PhotosPickerItem]) {
        isLoading = true
        selectedImages.removeAll()

        let group = DispatchGroup()
        var loadedImages: [UIImage] = []

        for item in items {
            group.enter()
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result, let data = data, let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            selectedImages = loadedImages
            formState.setValue(loadedImages, forKey: key)
            formState.touchField(key)
            isLoading = false
        }
    }

    private func removeImage(at index: Int) {
        selectedImages.remove(at: index)
        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }
        formState.setValue(selectedImages, forKey: key)
    }

    private var errorMessage: String? {
        guard formState.fields[key]?.isTouched == true else { return nil }
        return formState.fields[key]?.validationResult.errorMessage
    }
}
