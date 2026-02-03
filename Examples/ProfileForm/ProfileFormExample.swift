import SwiftUI
import SwiftUIFormsKit

// MARK: - Profile Form Example

/// A comprehensive user profile form demonstrating validation and various field types
public struct ProfileFormExample: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var validationState = FormValidationState()
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                // Profile picture section
                profilePictureSection
                
                // Personal information section
                personalInfoSection
                
                // Contact information section
                contactInfoSection
                
                // Address section
                addressSection
                
                // Social links section
                socialLinksSection
                
                // Bio section
                bioSection
                
                // Preferences section
                preferencesSection
                
                // Privacy section
                privacySection
                
                // Actions section
                actionsSection
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(!validationState.isValid)
                }
            }
            .alert("Profile Saved", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("Your profile has been updated successfully.")
            }
            .onAppear {
                setupValidation()
            }
        }
    }
    
    // MARK: - Profile Picture Section
    
    private var profilePictureSection: some View {
        Section {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        if let initials = viewModel.initials {
                            Text(initials)
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.accentColor)
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.accentColor)
                        }
                        
                        // Edit badge
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 35, y: 35)
                    }
                    
                    Button("Change Photo") {
                        viewModel.showPhotoPicker = true
                    }
                    .font(.subheadline)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Personal Info Section
    
    private var personalInfoSection: some View {
        Section("Personal Information") {
            // First name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("First Name", text: $viewModel.firstName)
                    .textContentType(.givenName)
            }
            .formValidation(validationState, field: "firstName", value: $viewModel.firstName)
            
            // Last name
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("Last Name", text: $viewModel.lastName)
                    .textContentType(.familyName)
            }
            .formValidation(validationState, field: "lastName", value: $viewModel.lastName)
            
            // Username
            HStack {
                Image(systemName: "at")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .autocapitalization(.none)
            }
            .formValidation(validationState, field: "username", value: $viewModel.username)
            
            // Date of birth
            DatePicker(
                selection: $viewModel.dateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            ) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Date of Birth")
                }
            }
            
            // Gender
            Picker(selection: $viewModel.gender) {
                ForEach(Gender.allCases) { gender in
                    Text(gender.rawValue).tag(gender)
                }
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Gender")
                }
            }
        }
    }
    
    // MARK: - Contact Info Section
    
    private var contactInfoSection: some View {
        Section("Contact Information") {
            // Email
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            .formValidation(validationState, field: "email", value: $viewModel.email)
            
            // Phone
            HStack {
                Image(systemName: "phone.fill")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("Phone Number", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
            .formValidation(validationState, field: "phone", value: $viewModel.phone)
            
            // Website
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField("Website", text: $viewModel.website)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
            .formValidation(validationState, field: "website", value: $viewModel.website)
        }
    }
    
    // MARK: - Address Section
    
    private var addressSection: some View {
        Section("Address") {
            FormAddressField(
                "",
                address: $viewModel.address,
                configuration: AddressFieldConfiguration(
                    showStreet2: true,
                    showCountry: true,
                    enableAutocomplete: true,
                    style: .stacked
                )
            )
        }
    }
    
    // MARK: - Social Links Section
    
    private var socialLinksSection: some View {
        Section("Social Links") {
            // Twitter
            HStack {
                Image(systemName: "at")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("twitter.com/")
                    .foregroundColor(.secondary)
                
                TextField("username", text: $viewModel.twitterHandle)
                    .autocapitalization(.none)
            }
            
            // LinkedIn
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("linkedin.com/in/")
                    .foregroundColor(.secondary)
                
                TextField("profile", text: $viewModel.linkedInProfile)
                    .autocapitalization(.none)
            }
            
            // GitHub
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Text("github.com/")
                    .foregroundColor(.secondary)
                
                TextField("username", text: $viewModel.githubUsername)
                    .autocapitalization(.none)
            }
        }
    }
    
    // MARK: - Bio Section
    
    private var bioSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                TextField("Bio", text: $viewModel.bio, axis: .vertical)
                    .lineLimit(4...8)
                
                HStack {
                    Spacer()
                    Text("\(viewModel.bio.count)/500")
                        .font(.caption)
                        .foregroundColor(viewModel.bio.count > 500 ? .red : .secondary)
                }
            }
            
            // Interests
            VStack(alignment: .leading, spacing: 8) {
                Text("Interests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(Interest.allCases) { interest in
                        InterestTag(
                            interest: interest,
                            isSelected: viewModel.interests.contains(interest),
                            onTap: {
                                if viewModel.interests.contains(interest) {
                                    viewModel.interests.remove(interest)
                                } else {
                                    viewModel.interests.insert(interest)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        Section("Preferences") {
            // Language
            Picker(selection: $viewModel.language) {
                ForEach(Language.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            } label: {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Language")
                }
            }
            
            // Timezone
            Picker(selection: $viewModel.timezone) {
                ForEach(Timezone.common) { tz in
                    Text(tz.displayName).tag(tz)
                }
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Timezone")
                }
            }
            
            // Currency
            Picker(selection: $viewModel.currency) {
                ForEach(Currency.common) { currency in
                    Text("\(currency.symbol) \(currency.code)").tag(currency)
                }
            } label: {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Currency")
                }
            }
        }
    }
    
    // MARK: - Privacy Section
    
    private var privacySection: some View {
        Section("Privacy") {
            Toggle(isOn: $viewModel.profilePublic) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Public Profile")
                    Text("Anyone can view your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $viewModel.showEmail) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Email")
                    Text("Display email on your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $viewModel.showLocation) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Show Location")
                    Text("Display city on your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Toggle(isOn: $viewModel.allowMessaging) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Allow Messages")
                    Text("Others can send you direct messages")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        Section {
            Button("Export Data") {
                viewModel.exportData()
            }
            
            Button("Delete Account", role: .destructive) {
                viewModel.showDeleteConfirmation = true
            }
        }
        .confirmationDialog(
            "Delete Account",
            isPresented: $viewModel.showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
    
    // MARK: - Helpers
    
    private func setupValidation() {
        validationState.register(field: "firstName") {
            AnyValidationRule.required("First name is required")
            AnyValidationRule.minLength(2, message: "First name must be at least 2 characters")
        }
        
        validationState.register(field: "lastName") {
            AnyValidationRule.required("Last name is required")
            AnyValidationRule.minLength(2, message: "Last name must be at least 2 characters")
        }
        
        validationState.register(field: "username") {
            AnyValidationRule.required("Username is required")
            AnyValidationRule.minLength(3, message: "Username must be at least 3 characters")
            AnyValidationRule.maxLength(20, message: "Username cannot exceed 20 characters")
            AnyValidationRule.pattern("^[a-zA-Z][a-zA-Z0-9_]*$", message: "Username can only contain letters, numbers, and underscores")
        }
        
        validationState.register(field: "email") {
            AnyValidationRule.required("Email is required")
            AnyValidationRule.email()
        }
        
        validationState.register(field: "phone") {
            AnyValidationRule.custom("Invalid phone number") { value in
                value.isEmpty || value.filter { $0.isNumber }.count >= 10
            }
        }
        
        validationState.register(field: "website") {
            AnyValidationRule.custom("Invalid URL") { value in
                value.isEmpty || URL(string: value) != nil
            }
        }
    }
    
    private func saveProfile() {
        guard validationState.validateAll() else { return }
        viewModel.saveProfile()
    }
}

// MARK: - Profile View Model

@MainActor
class ProfileViewModel: ObservableObject {
    // Personal
    @Published var firstName = "John"
    @Published var lastName = "Doe"
    @Published var username = "johndoe"
    @Published var dateOfBirth = Calendar.current.date(byAdding: .year, value: -25, to: Date())!
    @Published var gender: Gender = .preferNotToSay
    
    // Contact
    @Published var email = "john.doe@example.com"
    @Published var phone = ""
    @Published var website = ""
    
    // Address
    @Published var address = PostalAddress()
    
    // Social
    @Published var twitterHandle = ""
    @Published var linkedInProfile = ""
    @Published var githubUsername = ""
    
    // Bio
    @Published var bio = ""
    @Published var interests: Set<Interest> = []
    
    // Preferences
    @Published var language: Language = .english
    @Published var timezone: Timezone = .utc
    @Published var currency: Currency = .usd
    
    // Privacy
    @Published var profilePublic = true
    @Published var showEmail = false
    @Published var showLocation = true
    @Published var allowMessaging = true
    
    // UI State
    @Published var showPhotoPicker = false
    @Published var showSaveConfirmation = false
    @Published var showDeleteConfirmation = false
    
    var initials: String? {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        let result = firstInitial + lastInitial
        return result.isEmpty ? nil : result
    }
    
    func saveProfile() {
        // Simulate save
        showSaveConfirmation = true
    }
    
    func exportData() {
        // Export data implementation
    }
    
    func deleteAccount() {
        // Delete account implementation
    }
}

// MARK: - Supporting Types

enum Gender: String, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case nonBinary = "Non-Binary"
    case preferNotToSay = "Prefer not to say"
    
    var id: String { rawValue }
}

enum Interest: String, CaseIterable, Identifiable {
    case technology = "Technology"
    case design = "Design"
    case business = "Business"
    case art = "Art"
    case music = "Music"
    case sports = "Sports"
    case travel = "Travel"
    case food = "Food"
    case gaming = "Gaming"
    case photography = "Photography"
    
    var id: String { rawValue }
}

enum Language: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case japanese = "ja"
    case chinese = "zh"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
}

struct Timezone: Identifiable, Hashable {
    let id: String
    let displayName: String
    let offset: Int
    
    static let utc = Timezone(id: "UTC", displayName: "UTC", offset: 0)
    
    static let common: [Timezone] = [
        Timezone(id: "PST", displayName: "Pacific Time (US)", offset: -8),
        Timezone(id: "EST", displayName: "Eastern Time (US)", offset: -5),
        Timezone(id: "GMT", displayName: "Greenwich Mean Time", offset: 0),
        Timezone(id: "CET", displayName: "Central European Time", offset: 1),
        Timezone(id: "IST", displayName: "India Standard Time", offset: 5),
        Timezone(id: "JST", displayName: "Japan Standard Time", offset: 9)
    ]
}

struct Currency: Identifiable, Hashable {
    let id: String
    let code: String
    let symbol: String
    
    static let usd = Currency(id: "usd", code: "USD", symbol: "$")
    
    static let common: [Currency] = [
        Currency(id: "usd", code: "USD", symbol: "$"),
        Currency(id: "eur", code: "EUR", symbol: "€"),
        Currency(id: "gbp", code: "GBP", symbol: "£"),
        Currency(id: "jpy", code: "JPY", symbol: "¥"),
        Currency(id: "try", code: "TRY", symbol: "₺")
    ]
}

// MARK: - Interest Tag

struct InterestTag: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(interest.rawValue)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }
        
        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

// MARK: - Preview

#if DEBUG
struct ProfileFormExample_Previews: PreviewProvider {
    static var previews: some View {
        ProfileFormExample()
    }
}
#endif
