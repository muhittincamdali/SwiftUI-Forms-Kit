import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

// MARK: - File Type

/// Supported file types for upload
public enum FileType: String, CaseIterable {
    case image
    case video
    case audio
    case pdf
    case document
    case spreadsheet
    case archive
    case any
    
    var utTypes: [UTType] {
        switch self {
        case .image: return [.image, .jpeg, .png, .gif, .heic, .webP]
        case .video: return [.movie, .video, .mpeg4Movie, .quickTimeMovie]
        case .audio: return [.audio, .mp3, .wav, .aiff]
        case .pdf: return [.pdf]
        case .document: return [.text, .plainText, .rtf, .html]
        case .spreadsheet: return [.spreadsheet]
        case .archive: return [.archive, .zip, .gzip]
        case .any: return [.item]
        }
    }
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .video: return "video"
        case .audio: return "waveform"
        case .pdf: return "doc.fill"
        case .document: return "doc.text"
        case .spreadsheet: return "tablecells"
        case .archive: return "archivebox"
        case .any: return "folder"
        }
    }
}

// MARK: - Uploaded File

/// Represents an uploaded file
public struct UploadedFile: Identifiable {
    public let id: UUID
    public let name: String
    public let size: Int64
    public let type: UTType?
    public let url: URL?
    public let data: Data?
    public let thumbnail: Image?
    
    public init(
        id: UUID = UUID(),
        name: String,
        size: Int64 = 0,
        type: UTType? = nil,
        url: URL? = nil,
        data: Data? = nil,
        thumbnail: Image? = nil
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.type = type
        self.url = url
        self.data = data
        self.thumbnail = thumbnail
    }
    
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    public var iconName: String {
        if let type = type {
            if type.conforms(to: .image) { return "photo" }
            if type.conforms(to: .video) { return "video" }
            if type.conforms(to: .audio) { return "waveform" }
            if type.conforms(to: .pdf) { return "doc.fill" }
        }
        return "doc"
    }
}

// MARK: - File Upload Field

/// File upload field with drag & drop support
public struct FormFileUpload: View {
    @Binding private var files: [UploadedFile]
    
    private let label: String
    private let allowedTypes: [FileType]
    private let maxFiles: Int
    private let maxFileSize: Int64
    private let showPreview: Bool
    private let onUpload: ((UploadedFile) async -> Bool)?
    
    @State private var isShowingFilePicker = false
    @State private var isDropTargeted = false
    @State private var uploadProgress: [UUID: Double] = [:]
    @State private var errorMessage: String?
    
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        files: Binding<[UploadedFile]>,
        allowedTypes: [FileType] = [.any],
        maxFiles: Int = 10,
        maxFileSize: Int64 = 10_000_000, // 10MB
        showPreview: Bool = true,
        onUpload: ((UploadedFile) async -> Bool)? = nil
    ) {
        self.label = label
        self._files = files
        self.allowedTypes = allowedTypes
        self.maxFiles = maxFiles
        self.maxFileSize = maxFileSize
        self.showPreview = showPreview
        self.onUpload = onUpload
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
                
                Spacer()
                
                Text("\(files.count)/\(maxFiles)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Drop zone
            dropZone
            
            // File list
            if !files.isEmpty && showPreview {
                fileList
            }
            
            // Error message
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(theme.errorColor)
            }
            
            // Allowed types hint
            Text("Allowed: \(allowedTypesText)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: allowedUTTypes,
            allowsMultipleSelection: maxFiles > 1
        ) { result in
            handleFileImport(result)
        }
    }
    
    // MARK: - Drop Zone
    
    private var dropZone: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.up.doc")
                .font(.system(size: 40))
                .foregroundColor(isDropTargeted ? theme.primaryColor : .secondary)
            
            Text("Drag & drop files here")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("or")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { isShowingFilePicker = true }) {
                Text("Browse Files")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(theme.primaryColor)
                    )
            }
            .disabled(files.count >= maxFiles)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .foregroundColor(isDropTargeted ? theme.primaryColor : theme.borderColor)
        )
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .fill(isDropTargeted ? theme.primaryColor.opacity(0.05) : Color.clear)
        )
        .dropDestination(for: Data.self) { items, _ in
            handleDrop(items)
            return true
        } isTargeted: { isTargeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                isDropTargeted = isTargeted
            }
        }
    }
    
    // MARK: - File List
    
    private var fileList: some View {
        VStack(spacing: 8) {
            ForEach(files) { file in
                fileRow(file)
            }
        }
    }
    
    private func fileRow(_ file: UploadedFile) -> some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            Group {
                if let thumbnail = file.thumbnail {
                    thumbnail
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: file.iconName)
                        .font(.title2)
                        .foregroundColor(theme.primaryColor)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.primaryColor.opacity(0.1))
                        )
                }
            }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress or remove button
            if let progress = uploadProgress[file.id] {
                ProgressView(value: progress)
                    .frame(width: 60)
            } else {
                Button(action: { removeFile(file) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    // MARK: - Helpers
    
    private var allowedUTTypes: [UTType] {
        allowedTypes.flatMap { $0.utTypes }
    }
    
    private var allowedTypesText: String {
        if allowedTypes.contains(.any) {
            return "All files"
        }
        return allowedTypes.map { $0.rawValue }.joined(separator: ", ")
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                guard files.count < maxFiles else {
                    errorMessage = "Maximum \(maxFiles) files allowed"
                    return
                }
                addFile(from: url)
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleDrop(_ items: [Data]) {
        // Handle dropped data
        for data in items {
            guard files.count < maxFiles else {
                errorMessage = "Maximum \(maxFiles) files allowed"
                return
            }
            
            if data.count > maxFileSize {
                errorMessage = "File exceeds maximum size of \(ByteCountFormatter.string(fromByteCount: maxFileSize, countStyle: .file))"
                continue
            }
            
            let file = UploadedFile(
                name: "Dropped file",
                size: Int64(data.count),
                data: data
            )
            files.append(file)
        }
    }
    
    private func addFile(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let size = attributes[.size] as? Int64 ?? 0
            
            if size > maxFileSize {
                errorMessage = "File exceeds maximum size"
                return
            }
            
            let data = try Data(contentsOf: url)
            let type = UTType(filenameExtension: url.pathExtension)
            
            var thumbnail: Image?
            if let type = type, type.conforms(to: .image), let uiImage = UIImage(data: data) {
                thumbnail = Image(uiImage: uiImage)
            }
            
            let file = UploadedFile(
                name: url.lastPathComponent,
                size: size,
                type: type,
                url: url,
                data: data,
                thumbnail: thumbnail
            )
            
            files.append(file)
            errorMessage = nil
            
            // Trigger upload callback
            if let onUpload = onUpload {
                uploadProgress[file.id] = 0
                Task {
                    // Simulate progress
                    for i in 1...10 {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        await MainActor.run {
                            uploadProgress[file.id] = Double(i) / 10.0
                        }
                    }
                    
                    let success = await onUpload(file)
                    await MainActor.run {
                        uploadProgress.removeValue(forKey: file.id)
                        if !success {
                            files.removeAll { $0.id == file.id }
                            errorMessage = "Upload failed"
                        }
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func removeFile(_ file: UploadedFile) {
        files.removeAll { $0.id == file.id }
    }
}

// MARK: - Image Picker Field

/// Simplified image picker using PhotosUI
public struct FormImagePicker: View {
    @Binding private var selectedImages: [UIImage]
    
    private let label: String
    private let maxSelection: Int
    private let allowsEditing: Bool
    
    @State private var photosPickerItems: [PhotosPickerItem] = []
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        images: Binding<[UIImage]>,
        maxSelection: Int = 1,
        allowsEditing: Bool = false
    ) {
        self.label = label
        self._selectedImages = images
        self.maxSelection = maxSelection
        self.allowsEditing = allowsEditing
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(theme.labelColor)
            
            PhotosPicker(
                selection: $photosPickerItems,
                maxSelectionCount: maxSelection,
                matching: .images
            ) {
                if selectedImages.isEmpty {
                    emptyState
                } else {
                    imagePreview
                }
            }
            .onChange(of: photosPickerItems) { _, newItems in
                loadImages(from: newItems)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Tap to select images")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: theme.cornerRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .foregroundColor(theme.borderColor)
        )
    }
    
    private var imagePreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    Image(uiImage: selectedImages[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .topTrailing) {
                            Button(action: { selectedImages.remove(at: index) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 4, y: -4)
                        }
                }
                
                // Add more button
                if selectedImages.count < maxSelection {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 80, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(theme.borderColor)
                    )
                }
            }
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages.removeAll()
        
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 30) {
            FormFileUpload(
                "Upload Documents",
                files: .constant([
                    UploadedFile(name: "document.pdf", size: 1024000)
                ]),
                allowedTypes: [.pdf, .document]
            )
            
            FormImagePicker(
                "Product Images",
                images: .constant([]),
                maxSelection: 5
            )
        }
        .padding()
    }
}
