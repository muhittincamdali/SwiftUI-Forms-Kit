import SwiftUI
import Combine
import MapKit
import CoreLocation

// MARK: - Address Model

/// Represents a complete postal address with all standard components
public struct PostalAddress: Codable, Equatable, Hashable {
    public var street1: String
    public var street2: String
    public var city: String
    public var state: String
    public var postalCode: String
    public var country: String
    public var latitude: Double?
    public var longitude: Double?
    
    public init(
        street1: String = "",
        street2: String = "",
        city: String = "",
        state: String = "",
        postalCode: String = "",
        country: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.street1 = street1
        self.street2 = street2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Returns a formatted single-line address string
    public var formattedSingleLine: String {
        var components: [String] = []
        if !street1.isEmpty { components.append(street1) }
        if !street2.isEmpty { components.append(street2) }
        if !city.isEmpty { components.append(city) }
        if !state.isEmpty { components.append(state) }
        if !postalCode.isEmpty { components.append(postalCode) }
        if !country.isEmpty { components.append(country) }
        return components.joined(separator: ", ")
    }
    
    /// Returns a formatted multi-line address string
    public var formattedMultiLine: String {
        var lines: [String] = []
        if !street1.isEmpty { lines.append(street1) }
        if !street2.isEmpty { lines.append(street2) }
        var cityLine: [String] = []
        if !city.isEmpty { cityLine.append(city) }
        if !state.isEmpty { cityLine.append(state) }
        if !postalCode.isEmpty { cityLine.append(postalCode) }
        if !cityLine.isEmpty { lines.append(cityLine.joined(separator: ", ")) }
        if !country.isEmpty { lines.append(country) }
        return lines.joined(separator: "\n")
    }
    
    /// Checks if the address has all required fields filled
    public var isComplete: Bool {
        !street1.isEmpty && !city.isEmpty && !state.isEmpty && 
        !postalCode.isEmpty && !country.isEmpty
    }
    
    /// Checks if the address is completely empty
    public var isEmpty: Bool {
        street1.isEmpty && street2.isEmpty && city.isEmpty && 
        state.isEmpty && postalCode.isEmpty && country.isEmpty
    }
    
    /// Returns a CLLocationCoordinate2D if coordinates are available
    public var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

// MARK: - Address Autocomplete Provider

/// Protocol for address autocomplete services
public protocol AddressAutocompleteProvider {
    func search(query: String) async throws -> [AddressSuggestion]
    func getDetails(for suggestion: AddressSuggestion) async throws -> PostalAddress
}

/// Represents an address suggestion from autocomplete
public struct AddressSuggestion: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let mapItem: MKMapItem?
    
    public init(id: String, title: String, subtitle: String, mapItem: MKMapItem? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.mapItem = mapItem
    }
    
    public static func == (lhs: AddressSuggestion, rhs: AddressSuggestion) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Apple Maps Autocomplete Provider

/// Default autocomplete provider using Apple's MapKit
public class AppleMapsAutocompleteProvider: AddressAutocompleteProvider {
    private let completer: MKLocalSearchCompleter
    private var searchContinuation: CheckedContinuation<[AddressSuggestion], Error>?
    private let delegate: SearchCompleterDelegate
    
    public init() {
        self.completer = MKLocalSearchCompleter()
        self.delegate = SearchCompleterDelegate()
        self.completer.delegate = delegate
        self.completer.resultTypes = .address
    }
    
    public func search(query: String) async throws -> [AddressSuggestion] {
        guard !query.isEmpty else { return [] }
        
        return try await withCheckedThrowingContinuation { continuation in
            delegate.onResults = { results in
                let suggestions = results.map { result in
                    AddressSuggestion(
                        id: UUID().uuidString,
                        title: result.title,
                        subtitle: result.subtitle
                    )
                }
                continuation.resume(returning: suggestions)
            }
            delegate.onError = { error in
                continuation.resume(throwing: error)
            }
            completer.queryFragment = query
        }
    }
    
    public func getDetails(for suggestion: AddressSuggestion) async throws -> PostalAddress {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = "\(suggestion.title) \(suggestion.subtitle)"
        
        let search = MKLocalSearch(request: searchRequest)
        let response = try await search.start()
        
        guard let mapItem = response.mapItems.first else {
            throw AddressError.notFound
        }
        
        let placemark = mapItem.placemark
        return PostalAddress(
            street1: [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }.joined(separator: " "),
            street2: "",
            city: placemark.locality ?? "",
            state: placemark.administrativeArea ?? "",
            postalCode: placemark.postalCode ?? "",
            country: placemark.country ?? "",
            latitude: placemark.coordinate.latitude,
            longitude: placemark.coordinate.longitude
        )
    }
}

/// Delegate for MKLocalSearchCompleter
private class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onResults: (([MKLocalSearchCompletion]) -> Void)?
    var onError: ((Error) -> Void)?
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onResults?(completer.results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError?(error)
    }
}

// MARK: - Address Errors

public enum AddressError: LocalizedError {
    case notFound
    case invalidFormat
    case geocodingFailed
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "Address not found"
        case .invalidFormat:
            return "Invalid address format"
        case .geocodingFailed:
            return "Failed to geocode address"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Address Field Configuration

/// Configuration options for FormAddressField
public struct AddressFieldConfiguration {
    public var showStreet2: Bool
    public var showCountry: Bool
    public var enableAutocomplete: Bool
    public var enableMapPreview: Bool
    public var countries: [Country]
    public var defaultCountry: String
    public var style: AddressFieldStyle
    
    public init(
        showStreet2: Bool = true,
        showCountry: Bool = true,
        enableAutocomplete: Bool = true,
        enableMapPreview: Bool = false,
        countries: [Country] = Country.commonCountries,
        defaultCountry: String = "United States",
        style: AddressFieldStyle = .stacked
    ) {
        self.showStreet2 = showStreet2
        self.showCountry = showCountry
        self.enableAutocomplete = enableAutocomplete
        self.enableMapPreview = enableMapPreview
        self.countries = countries
        self.defaultCountry = defaultCountry
        self.style = style
    }
    
    public static let `default` = AddressFieldConfiguration()
    public static let minimal = AddressFieldConfiguration(
        showStreet2: false,
        showCountry: false,
        enableAutocomplete: false
    )
    public static let full = AddressFieldConfiguration(
        showStreet2: true,
        showCountry: true,
        enableAutocomplete: true,
        enableMapPreview: true
    )
}

/// Display style for address fields
public enum AddressFieldStyle {
    case stacked
    case inline
    case grouped
}

// MARK: - Country Model

/// Represents a country with its code and states/provinces
public struct Country: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let code: String
    public let flag: String
    public let states: [StateProvince]
    public let postalCodeFormat: String?
    public let postalCodeRegex: String?
    
    public init(
        name: String,
        code: String,
        flag: String,
        states: [StateProvince] = [],
        postalCodeFormat: String? = nil,
        postalCodeRegex: String? = nil
    ) {
        self.id = code
        self.name = name
        self.code = code
        self.flag = flag
        self.states = states
        self.postalCodeFormat = postalCodeFormat
        self.postalCodeRegex = postalCodeRegex
    }
    
    public static let commonCountries: [Country] = [
        Country(
            name: "United States",
            code: "US",
            flag: "🇺🇸",
            states: StateProvince.usStates,
            postalCodeFormat: "#####",
            postalCodeRegex: "^\\d{5}(-\\d{4})?$"
        ),
        Country(
            name: "Canada",
            code: "CA",
            flag: "🇨🇦",
            states: StateProvince.canadianProvinces,
            postalCodeFormat: "A#A #A#",
            postalCodeRegex: "^[A-Za-z]\\d[A-Za-z][ -]?\\d[A-Za-z]\\d$"
        ),
        Country(
            name: "United Kingdom",
            code: "GB",
            flag: "🇬🇧",
            states: StateProvince.ukCounties,
            postalCodeFormat: "AA## #AA",
            postalCodeRegex: "^[A-Za-z]{1,2}\\d[A-Za-z\\d]? ?\\d[A-Za-z]{2}$"
        ),
        Country(name: "Germany", code: "DE", flag: "🇩🇪", postalCodeFormat: "#####"),
        Country(name: "France", code: "FR", flag: "🇫🇷", postalCodeFormat: "#####"),
        Country(name: "Australia", code: "AU", flag: "🇦🇺", states: StateProvince.australianStates),
        Country(name: "Japan", code: "JP", flag: "🇯🇵", postalCodeFormat: "###-####"),
        Country(name: "Turkey", code: "TR", flag: "🇹🇷", postalCodeFormat: "#####")
    ]
}

/// Represents a state or province within a country
public struct StateProvince: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let abbreviation: String
    
    public init(name: String, abbreviation: String) {
        self.id = abbreviation
        self.name = name
        self.abbreviation = abbreviation
    }
    
    public static let usStates: [StateProvince] = [
        StateProvince(name: "Alabama", abbreviation: "AL"),
        StateProvince(name: "Alaska", abbreviation: "AK"),
        StateProvince(name: "Arizona", abbreviation: "AZ"),
        StateProvince(name: "Arkansas", abbreviation: "AR"),
        StateProvince(name: "California", abbreviation: "CA"),
        StateProvince(name: "Colorado", abbreviation: "CO"),
        StateProvince(name: "Connecticut", abbreviation: "CT"),
        StateProvince(name: "Delaware", abbreviation: "DE"),
        StateProvince(name: "Florida", abbreviation: "FL"),
        StateProvince(name: "Georgia", abbreviation: "GA"),
        StateProvince(name: "Hawaii", abbreviation: "HI"),
        StateProvince(name: "Idaho", abbreviation: "ID"),
        StateProvince(name: "Illinois", abbreviation: "IL"),
        StateProvince(name: "Indiana", abbreviation: "IN"),
        StateProvince(name: "Iowa", abbreviation: "IA"),
        StateProvince(name: "Kansas", abbreviation: "KS"),
        StateProvince(name: "Kentucky", abbreviation: "KY"),
        StateProvince(name: "Louisiana", abbreviation: "LA"),
        StateProvince(name: "Maine", abbreviation: "ME"),
        StateProvince(name: "Maryland", abbreviation: "MD"),
        StateProvince(name: "Massachusetts", abbreviation: "MA"),
        StateProvince(name: "Michigan", abbreviation: "MI"),
        StateProvince(name: "Minnesota", abbreviation: "MN"),
        StateProvince(name: "Mississippi", abbreviation: "MS"),
        StateProvince(name: "Missouri", abbreviation: "MO"),
        StateProvince(name: "Montana", abbreviation: "MT"),
        StateProvince(name: "Nebraska", abbreviation: "NE"),
        StateProvince(name: "Nevada", abbreviation: "NV"),
        StateProvince(name: "New Hampshire", abbreviation: "NH"),
        StateProvince(name: "New Jersey", abbreviation: "NJ"),
        StateProvince(name: "New Mexico", abbreviation: "NM"),
        StateProvince(name: "New York", abbreviation: "NY"),
        StateProvince(name: "North Carolina", abbreviation: "NC"),
        StateProvince(name: "North Dakota", abbreviation: "ND"),
        StateProvince(name: "Ohio", abbreviation: "OH"),
        StateProvince(name: "Oklahoma", abbreviation: "OK"),
        StateProvince(name: "Oregon", abbreviation: "OR"),
        StateProvince(name: "Pennsylvania", abbreviation: "PA"),
        StateProvince(name: "Rhode Island", abbreviation: "RI"),
        StateProvince(name: "South Carolina", abbreviation: "SC"),
        StateProvince(name: "South Dakota", abbreviation: "SD"),
        StateProvince(name: "Tennessee", abbreviation: "TN"),
        StateProvince(name: "Texas", abbreviation: "TX"),
        StateProvince(name: "Utah", abbreviation: "UT"),
        StateProvince(name: "Vermont", abbreviation: "VT"),
        StateProvince(name: "Virginia", abbreviation: "VA"),
        StateProvince(name: "Washington", abbreviation: "WA"),
        StateProvince(name: "West Virginia", abbreviation: "WV"),
        StateProvince(name: "Wisconsin", abbreviation: "WI"),
        StateProvince(name: "Wyoming", abbreviation: "WY")
    ]
    
    public static let canadianProvinces: [StateProvince] = [
        StateProvince(name: "Alberta", abbreviation: "AB"),
        StateProvince(name: "British Columbia", abbreviation: "BC"),
        StateProvince(name: "Manitoba", abbreviation: "MB"),
        StateProvince(name: "New Brunswick", abbreviation: "NB"),
        StateProvince(name: "Newfoundland and Labrador", abbreviation: "NL"),
        StateProvince(name: "Nova Scotia", abbreviation: "NS"),
        StateProvince(name: "Ontario", abbreviation: "ON"),
        StateProvince(name: "Prince Edward Island", abbreviation: "PE"),
        StateProvince(name: "Quebec", abbreviation: "QC"),
        StateProvince(name: "Saskatchewan", abbreviation: "SK")
    ]
    
    public static let ukCounties: [StateProvince] = [
        StateProvince(name: "England", abbreviation: "ENG"),
        StateProvince(name: "Scotland", abbreviation: "SCT"),
        StateProvince(name: "Wales", abbreviation: "WLS"),
        StateProvince(name: "Northern Ireland", abbreviation: "NIR")
    ]
    
    public static let australianStates: [StateProvince] = [
        StateProvince(name: "New South Wales", abbreviation: "NSW"),
        StateProvince(name: "Victoria", abbreviation: "VIC"),
        StateProvince(name: "Queensland", abbreviation: "QLD"),
        StateProvince(name: "Western Australia", abbreviation: "WA"),
        StateProvince(name: "South Australia", abbreviation: "SA"),
        StateProvince(name: "Tasmania", abbreviation: "TAS")
    ]
}

// MARK: - Form Address Field View

/// A comprehensive address input field with autocomplete and validation
public struct FormAddressField: View {
    @Binding private var address: PostalAddress
    private let label: String
    private let configuration: AddressFieldConfiguration
    private let onValidation: ((Bool) -> Void)?
    
    @State private var showSuggestions = false
    @State private var suggestions: [AddressSuggestion] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedCountry: Country?
    @State private var validationErrors: [String: String] = [:]
    @State private var showMapPreview = false
    
    @FocusState private var focusedField: AddressFieldType?
    
    private let autocompleteProvider: AddressAutocompleteProvider
    
    public init(
        _ label: String,
        address: Binding<PostalAddress>,
        configuration: AddressFieldConfiguration = .default,
        autocompleteProvider: AddressAutocompleteProvider? = nil,
        onValidation: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self._address = address
        self.configuration = configuration
        self.autocompleteProvider = autocompleteProvider ?? AppleMapsAutocompleteProvider()
        self.onValidation = onValidation
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !label.isEmpty {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            switch configuration.style {
            case .stacked:
                stackedLayout
            case .inline:
                inlineLayout
            case .grouped:
                groupedLayout
            }
            
            if configuration.enableMapPreview, let coordinate = address.coordinate {
                mapPreviewSection(coordinate: coordinate)
            }
        }
        .onAppear {
            setupInitialCountry()
        }
        .onChange(of: address) { _ in
            validateAddress()
        }
    }
    
    // MARK: - Stacked Layout
    
    private var stackedLayout: some View {
        VStack(spacing: 12) {
            // Street Address 1
            addressTextField(
                "Street Address",
                text: $address.street1,
                field: .street1,
                icon: "house.fill",
                error: validationErrors["street1"]
            )
            
            // Street Address 2 (optional)
            if configuration.showStreet2 {
                addressTextField(
                    "Apt, Suite, Unit (Optional)",
                    text: $address.street2,
                    field: .street2,
                    icon: "building.2.fill"
                )
            }
            
            // City
            addressTextField(
                "City",
                text: $address.city,
                field: .city,
                icon: "building.columns.fill",
                error: validationErrors["city"]
            )
            
            // State and Postal Code row
            HStack(spacing: 12) {
                statePickerField
                postalCodeField
            }
            
            // Country
            if configuration.showCountry {
                countryPickerField
            }
        }
    }
    
    // MARK: - Inline Layout
    
    private var inlineLayout: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                addressTextField(
                    "Street",
                    text: $address.street1,
                    field: .street1,
                    icon: "house.fill",
                    error: validationErrors["street1"]
                )
                
                if configuration.showStreet2 {
                    addressTextField(
                        "Apt/Suite",
                        text: $address.street2,
                        field: .street2,
                        icon: "building.2.fill"
                    )
                    .frame(width: 120)
                }
            }
            
            HStack(spacing: 12) {
                addressTextField(
                    "City",
                    text: $address.city,
                    field: .city,
                    icon: "building.columns.fill",
                    error: validationErrors["city"]
                )
                
                statePickerField
                    .frame(width: 100)
                
                postalCodeField
                    .frame(width: 100)
            }
            
            if configuration.showCountry {
                countryPickerField
            }
        }
    }
    
    // MARK: - Grouped Layout
    
    private var groupedLayout: some View {
        VStack(spacing: 16) {
            GroupBox("Street Address") {
                VStack(spacing: 8) {
                    TextField("Street Address", text: $address.street1)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .street1)
                    
                    if configuration.showStreet2 {
                        TextField("Apt, Suite, Unit", text: $address.street2)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .street2)
                    }
                }
                .padding(.vertical, 4)
            }
            
            GroupBox("Location") {
                VStack(spacing: 8) {
                    TextField("City", text: $address.city)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .city)
                    
                    HStack(spacing: 12) {
                        statePickerField
                        postalCodeField
                    }
                }
                .padding(.vertical, 4)
            }
            
            if configuration.showCountry {
                GroupBox("Country") {
                    countryPickerField
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Field Components
    
    private func addressTextField(
        _ placeholder: String,
        text: Binding<String>,
        field: AddressFieldType,
        icon: String,
        error: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: field)
                    .textContentType(field.textContentType)
                    .autocapitalization(field.autocapitalization)
                    .disableAutocorrection(field.disableAutocorrection)
                    .onChange(of: text.wrappedValue) { newValue in
                        if field == .street1 && configuration.enableAutocomplete {
                            performAutocomplete(query: newValue)
                        }
                    }
                
                if let error = error {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 36)
            }
            
            // Autocomplete suggestions
            if field == .street1 && showSuggestions && !suggestions.isEmpty {
                suggestionsList
            }
        }
    }
    
    private var statePickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let country = selectedCountry, !country.states.isEmpty {
                Picker("State", selection: $address.state) {
                    Text("Select State").tag("")
                    ForEach(country.states) { state in
                        Text(state.name).tag(state.abbreviation)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            } else {
                addressTextField(
                    "State/Province",
                    text: $address.state,
                    field: .state,
                    icon: "map.fill",
                    error: validationErrors["state"]
                )
            }
        }
    }
    
    private var postalCodeField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "number")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                TextField(postalCodePlaceholder, text: $address.postalCode)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .postalCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numbersAndPunctuation)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(validationErrors["postalCode"] != nil ? Color.red : Color.clear, lineWidth: 1)
            )
            
            if let error = validationErrors["postalCode"] {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 36)
            }
        }
    }
    
    private var countryPickerField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.secondary)
                    .frame(width: 24)
                
                Picker("Country", selection: $address.country) {
                    Text("Select Country").tag("")
                    ForEach(configuration.countries) { country in
                        HStack {
                            Text(country.flag)
                            Text(country.name)
                        }
                        .tag(country.name)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: address.country) { newValue in
                    selectedCountry = configuration.countries.first { $0.name == newValue }
                    address.state = ""
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions.prefix(5)) { suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.body)
                            .foregroundColor(.primary)
                        Text(suggestion.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                if suggestion.id != suggestions.prefix(5).last?.id {
                    Divider()
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.leading, 36)
    }
    
    private func mapPreviewSection(coordinate: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Location Preview")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    showMapPreview.toggle()
                } label: {
                    Image(systemName: showMapPreview ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if showMapPreview {
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )), annotationItems: [MapAnnotationItem(coordinate: coordinate)]) { item in
                    MapMarker(coordinate: item.coordinate, tint: .red)
                }
                .frame(height: 150)
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var postalCodePlaceholder: String {
        selectedCountry?.postalCodeFormat ?? "Postal Code"
    }
    
    private func setupInitialCountry() {
        if address.country.isEmpty {
            address.country = configuration.defaultCountry
        }
        selectedCountry = configuration.countries.first { $0.name == address.country }
    }
    
    private func performAutocomplete(query: String) {
        searchTask?.cancel()
        
        guard query.count >= 3 else {
            showSuggestions = false
            suggestions = []
            return
        }
        
        searchTask = Task {
            isSearching = true
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Debounce 300ms
                guard !Task.isCancelled else { return }
                
                let results = try await autocompleteProvider.search(query: query)
                await MainActor.run {
                    suggestions = results
                    showSuggestions = !results.isEmpty
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    showSuggestions = false
                }
            }
        }
    }
    
    private func selectSuggestion(_ suggestion: AddressSuggestion) {
        Task {
            do {
                let fullAddress = try await autocompleteProvider.getDetails(for: suggestion)
                await MainActor.run {
                    address = fullAddress
                    showSuggestions = false
                    suggestions = []
                    focusedField = nil
                }
            } catch {
                print("Failed to get address details: \(error)")
            }
        }
    }
    
    private func validateAddress() {
        var errors: [String: String] = [:]
        
        if address.street1.isEmpty {
            errors["street1"] = "Street address is required"
        }
        
        if address.city.isEmpty {
            errors["city"] = "City is required"
        }
        
        if address.state.isEmpty {
            errors["state"] = "State is required"
        }
        
        if address.postalCode.isEmpty {
            errors["postalCode"] = "Postal code is required"
        } else if let country = selectedCountry,
                  let regex = country.postalCodeRegex {
            let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
            if !predicate.evaluate(with: address.postalCode) {
                errors["postalCode"] = "Invalid postal code format"
            }
        }
        
        validationErrors = errors
        onValidation?(errors.isEmpty)
    }
}

// MARK: - Supporting Types

private enum AddressFieldType: Hashable {
    case street1
    case street2
    case city
    case state
    case postalCode
    case country
    
    var textContentType: UITextContentType? {
        switch self {
        case .street1: return .streetAddressLine1
        case .street2: return .streetAddressLine2
        case .city: return .addressCity
        case .state: return .addressState
        case .postalCode: return .postalCode
        case .country: return .countryName
        }
    }
    
    var autocapitalization: UITextAutocapitalizationType {
        switch self {
        case .street1, .street2, .city, .state, .country:
            return .words
        case .postalCode:
            return .allCharacters
        }
    }
    
    var disableAutocorrection: Bool {
        switch self {
        case .postalCode:
            return true
        default:
            return false
        }
    }
}

private struct MapAnnotationItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Preview

#if DEBUG
struct FormAddressField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                FormAddressField(
                    "Shipping Address",
                    address: .constant(PostalAddress())
                )
                
                FormAddressField(
                    "Billing Address",
                    address: .constant(PostalAddress(
                        street1: "123 Main Street",
                        city: "San Francisco",
                        state: "CA",
                        postalCode: "94102",
                        country: "United States"
                    )),
                    configuration: .full
                )
            }
            .padding()
        }
    }
}
#endif
