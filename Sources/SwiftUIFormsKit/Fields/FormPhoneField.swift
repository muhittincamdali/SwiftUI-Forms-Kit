import SwiftUI

// MARK: - Country Code

/// International country phone codes
public struct CountryCode: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let dialCode: String
    public let flag: String
    public let format: String
    
    public init(id: String, name: String, dialCode: String, flag: String, format: String = "") {
        self.id = id
        self.name = name
        self.dialCode = dialCode
        self.flag = flag
        self.format = format
    }
    
    /// Common country codes
    public static let countries: [CountryCode] = [
        CountryCode(id: "US", name: "United States", dialCode: "+1", flag: "🇺🇸", format: "(###) ###-####"),
        CountryCode(id: "GB", name: "United Kingdom", dialCode: "+44", flag: "🇬🇧", format: "#### ######"),
        CountryCode(id: "DE", name: "Germany", dialCode: "+49", flag: "🇩🇪", format: "### ########"),
        CountryCode(id: "FR", name: "France", dialCode: "+33", flag: "🇫🇷", format: "# ## ## ## ##"),
        CountryCode(id: "TR", name: "Turkey", dialCode: "+90", flag: "🇹🇷", format: "### ### ## ##"),
        CountryCode(id: "IT", name: "Italy", dialCode: "+39", flag: "🇮🇹", format: "### ### ####"),
        CountryCode(id: "ES", name: "Spain", dialCode: "+34", flag: "🇪🇸", format: "### ### ###"),
        CountryCode(id: "NL", name: "Netherlands", dialCode: "+31", flag: "🇳🇱", format: "# ########"),
        CountryCode(id: "BE", name: "Belgium", dialCode: "+32", flag: "🇧🇪", format: "### ## ## ##"),
        CountryCode(id: "CH", name: "Switzerland", dialCode: "+41", flag: "🇨🇭", format: "## ### ## ##"),
        CountryCode(id: "AT", name: "Austria", dialCode: "+43", flag: "🇦🇹", format: "### #######"),
        CountryCode(id: "PL", name: "Poland", dialCode: "+48", flag: "🇵🇱", format: "### ### ###"),
        CountryCode(id: "SE", name: "Sweden", dialCode: "+46", flag: "🇸🇪", format: "##-### ## ##"),
        CountryCode(id: "NO", name: "Norway", dialCode: "+47", flag: "🇳🇴", format: "### ## ###"),
        CountryCode(id: "DK", name: "Denmark", dialCode: "+45", flag: "🇩🇰", format: "## ## ## ##"),
        CountryCode(id: "FI", name: "Finland", dialCode: "+358", flag: "🇫🇮", format: "## ### ####"),
        CountryCode(id: "PT", name: "Portugal", dialCode: "+351", flag: "🇵🇹", format: "### ### ###"),
        CountryCode(id: "GR", name: "Greece", dialCode: "+30", flag: "🇬🇷", format: "### ### ####"),
        CountryCode(id: "IE", name: "Ireland", dialCode: "+353", flag: "🇮🇪", format: "## ### ####"),
        CountryCode(id: "CZ", name: "Czech Republic", dialCode: "+420", flag: "🇨🇿", format: "### ### ###"),
        CountryCode(id: "RU", name: "Russia", dialCode: "+7", flag: "🇷🇺", format: "### ###-##-##"),
        CountryCode(id: "UA", name: "Ukraine", dialCode: "+380", flag: "🇺🇦", format: "## ### ## ##"),
        CountryCode(id: "JP", name: "Japan", dialCode: "+81", flag: "🇯🇵", format: "##-####-####"),
        CountryCode(id: "CN", name: "China", dialCode: "+86", flag: "🇨🇳", format: "### #### ####"),
        CountryCode(id: "KR", name: "South Korea", dialCode: "+82", flag: "🇰🇷", format: "##-####-####"),
        CountryCode(id: "IN", name: "India", dialCode: "+91", flag: "🇮🇳", format: "##### #####"),
        CountryCode(id: "AU", name: "Australia", dialCode: "+61", flag: "🇦🇺", format: "### ### ###"),
        CountryCode(id: "NZ", name: "New Zealand", dialCode: "+64", flag: "🇳🇿", format: "## ### ####"),
        CountryCode(id: "CA", name: "Canada", dialCode: "+1", flag: "🇨🇦", format: "(###) ###-####"),
        CountryCode(id: "MX", name: "Mexico", dialCode: "+52", flag: "🇲🇽", format: "## #### ####"),
        CountryCode(id: "BR", name: "Brazil", dialCode: "+55", flag: "🇧🇷", format: "## #####-####"),
        CountryCode(id: "AR", name: "Argentina", dialCode: "+54", flag: "🇦🇷", format: "## ####-####"),
        CountryCode(id: "SA", name: "Saudi Arabia", dialCode: "+966", flag: "🇸🇦", format: "## ### ####"),
        CountryCode(id: "AE", name: "UAE", dialCode: "+971", flag: "🇦🇪", format: "## ### ####"),
        CountryCode(id: "EG", name: "Egypt", dialCode: "+20", flag: "🇪🇬", format: "### ### ####"),
        CountryCode(id: "ZA", name: "South Africa", dialCode: "+27", flag: "🇿🇦", format: "## ### ####"),
        CountryCode(id: "NG", name: "Nigeria", dialCode: "+234", flag: "🇳🇬", format: "### ### ####"),
        CountryCode(id: "KE", name: "Kenya", dialCode: "+254", flag: "🇰🇪", format: "### ######"),
        CountryCode(id: "SG", name: "Singapore", dialCode: "+65", flag: "🇸🇬", format: "#### ####"),
        CountryCode(id: "MY", name: "Malaysia", dialCode: "+60", flag: "🇲🇾", format: "##-### ####"),
        CountryCode(id: "TH", name: "Thailand", dialCode: "+66", flag: "🇹🇭", format: "## ### ####"),
        CountryCode(id: "ID", name: "Indonesia", dialCode: "+62", flag: "🇮🇩", format: "### ### ####"),
        CountryCode(id: "PH", name: "Philippines", dialCode: "+63", flag: "🇵🇭", format: "### ### ####"),
        CountryCode(id: "VN", name: "Vietnam", dialCode: "+84", flag: "🇻🇳", format: "## ### ## ##"),
        CountryCode(id: "IL", name: "Israel", dialCode: "+972", flag: "🇮🇱", format: "##-###-####"),
        CountryCode(id: "HK", name: "Hong Kong", dialCode: "+852", flag: "🇭🇰", format: "#### ####"),
        CountryCode(id: "TW", name: "Taiwan", dialCode: "+886", flag: "🇹🇼", format: "### ### ###")
    ]
}

// MARK: - Phone Field

/// International phone number input field with country code picker
public struct FormPhoneField: View {
    @Binding private var phoneNumber: String
    @Binding private var countryCode: CountryCode
    
    private let label: String
    private let placeholder: String
    private let countries: [CountryCode]
    private let showFlag: Bool
    private let autoFormat: Bool
    private let onValidate: ((String) -> Bool)?
    
    @State private var isShowingCountryPicker = false
    @State private var searchText = ""
    @State private var isValid = true
    @State private var isFocused = false
    @Environment(\.formTheme) private var theme
    
    public init(
        _ label: String,
        phoneNumber: Binding<String>,
        countryCode: Binding<CountryCode>,
        placeholder: String = "Phone number",
        countries: [CountryCode] = CountryCode.countries,
        showFlag: Bool = true,
        autoFormat: Bool = true,
        onValidate: ((String) -> Bool)? = nil
    ) {
        self.label = label
        self._phoneNumber = phoneNumber
        self._countryCode = countryCode
        self.placeholder = placeholder
        self.countries = countries
        self.showFlag = showFlag
        self.autoFormat = autoFormat
        self.onValidate = onValidate
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.labelColor)
            }
            
            // Input row
            HStack(spacing: 0) {
                // Country code button
                countryCodeButton
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 8)
                
                // Phone input
                TextField(placeholder, text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: phoneNumber) { _, newValue in
                        if autoFormat {
                            phoneNumber = formatPhoneNumber(newValue)
                        }
                        validatePhone()
                    }
                    .accessibilityLabel("\(label) phone number")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .background(
                RoundedRectangle(cornerRadius: theme.cornerRadius)
                    .fill(theme.backgroundColor)
            )
            
            // Validation message
            if !isValid {
                Text("Please enter a valid phone number")
                    .font(.caption)
                    .foregroundColor(theme.errorColor)
            }
            
            // Full number preview
            Text(fullPhoneNumber)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $isShowingCountryPicker) {
            countryPickerSheet
        }
    }
    
    // MARK: - Country Code Button
    
    private var countryCodeButton: some View {
        Button(action: { isShowingCountryPicker = true }) {
            HStack(spacing: 6) {
                if showFlag {
                    Text(countryCode.flag)
                        .font(.title2)
                }
                Text(countryCode.dialCode)
                    .font(.body)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
        }
        .accessibilityLabel("Country code \(countryCode.name)")
        .accessibilityHint("Double tap to change country")
    }
    
    // MARK: - Country Picker Sheet
    
    private var countryPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(filteredCountries) { country in
                    Button(action: {
                        countryCode = country
                        isShowingCountryPicker = false
                    }) {
                        HStack {
                            Text(country.flag)
                                .font(.title2)
                            Text(country.name)
                            Spacer()
                            Text(country.dialCode)
                                .foregroundColor(.secondary)
                            if country.id == countryCode.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(theme.primaryColor)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isShowingCountryPicker = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var filteredCountries: [CountryCode] {
        if searchText.isEmpty {
            return countries
        }
        return countries.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.dialCode.contains(searchText)
        }
    }
    
    private var borderColor: Color {
        if !isValid {
            return theme.errorColor
        }
        return isFocused ? theme.primaryColor : theme.borderColor
    }
    
    private var fullPhoneNumber: String {
        let cleanNumber = phoneNumber.filter { $0.isNumber }
        guard !cleanNumber.isEmpty else { return "" }
        return "\(countryCode.dialCode) \(phoneNumber)"
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        guard !digits.isEmpty, !countryCode.format.isEmpty else {
            return String(digits.prefix(15))
        }
        
        var result = ""
        var digitIndex = digits.startIndex
        
        for char in countryCode.format {
            guard digitIndex < digits.endIndex else { break }
            if char == "#" {
                result.append(digits[digitIndex])
                digitIndex = digits.index(after: digitIndex)
            } else {
                result.append(char)
            }
        }
        
        return result
    }
    
    private func validatePhone() {
        let digits = phoneNumber.filter { $0.isNumber }
        if let validator = onValidate {
            isValid = validator(digits)
        } else {
            isValid = digits.count >= 7 && digits.count <= 15
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State var phone = ""
        @State var country = CountryCode.countries[0]
        
        var body: some View {
            VStack(spacing: 20) {
                FormPhoneField(
                    "Phone Number",
                    phoneNumber: $phone,
                    countryCode: $country
                )
                .padding()
            }
        }
    }
    return PreviewWrapper()
}
