import SwiftUI
import SwiftUIFormsKit

// MARK: - Checkout Form Example

/// A complete e-commerce checkout form demonstrating all form kit features
public struct CheckoutFormExample: View {
    @StateObject private var viewModel = CheckoutViewModel()
    @StateObject private var wizardState: FormWizardState
    
    public init() {
        let steps = [
            AnyWizardStep(WizardStepModel(
                id: "cart",
                title: "Cart Review",
                subtitle: "Review your items",
                icon: "cart.fill"
            ) { Text("Cart") }),
            AnyWizardStep(WizardStepModel(
                id: "shipping",
                title: "Shipping",
                subtitle: "Delivery address",
                icon: "shippingbox.fill"
            ) { Text("Shipping") }),
            AnyWizardStep(WizardStepModel(
                id: "payment",
                title: "Payment",
                subtitle: "Payment details",
                icon: "creditcard.fill"
            ) { Text("Payment") }),
            AnyWizardStep(WizardStepModel(
                id: "review",
                title: "Review",
                subtitle: "Confirm order",
                icon: "checkmark.circle.fill"
            ) { Text("Review") })
        ]
        
        _wizardState = StateObject(wrappedValue: FormWizardState(
            steps: steps,
            configuration: FormWizardConfiguration(
                allowBackNavigation: true,
                validateOnStepChange: true,
                showProgressIndicator: true,
                animationStyle: .slide
            )
        ))
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                StepIndicator(
                    steps: [
                        StepItem(title: "Cart", icon: "cart.fill", status: stepStatus(for: 0)),
                        StepItem(title: "Shipping", icon: "shippingbox.fill", status: stepStatus(for: 1)),
                        StepItem(title: "Payment", icon: "creditcard.fill", status: stepStatus(for: 2)),
                        StepItem(title: "Review", icon: "checkmark.circle.fill", status: stepStatus(for: 3))
                    ],
                    configuration: StepIndicatorConfiguration(
                        style: .filled,
                        size: .medium,
                        showLabels: true,
                        showConnectors: true
                    )
                ) { index in
                    if index < wizardState.currentStepIndex || wizardState.isStepCompleted(index) {
                        wizardState.goToStep(index)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch wizardState.currentStepIndex {
                        case 0:
                            CartReviewStep(viewModel: viewModel)
                        case 1:
                            ShippingStep(viewModel: viewModel)
                        case 2:
                            PaymentStep(viewModel: viewModel)
                        case 3:
                            OrderReviewStep(viewModel: viewModel)
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                
                // Navigation
                navigationButtons
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Order Placed!", isPresented: $viewModel.showOrderConfirmation) {
                Button("OK") {
                    viewModel.reset()
                    wizardState.reset()
                }
            } message: {
                Text("Your order #\(viewModel.orderNumber) has been placed successfully.")
            }
        }
    }
    
    private func stepStatus(for index: Int) -> StepStatus {
        if index < wizardState.currentStepIndex {
            return .completed
        } else if index == wizardState.currentStepIndex {
            return .current
        } else {
            return .pending
        }
    }
    
    private var navigationButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if wizardState.currentStepIndex > 0 {
                    Button {
                        wizardState.goToPrevious()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    if wizardState.isLastStep {
                        viewModel.placeOrder()
                    } else {
                        wizardState.goToNext()
                    }
                } label: {
                    HStack {
                        Text(wizardState.isLastStep ? "Place Order" : "Continue")
                        if !wizardState.isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private var canProceed: Bool {
        switch wizardState.currentStepIndex {
        case 0: return !viewModel.cartItems.isEmpty
        case 1: return viewModel.shippingAddress.isComplete
        case 2: return viewModel.isPaymentValid
        case 3: return viewModel.agreedToTerms
        default: return true
        }
    }
}

// MARK: - Checkout View Model

@MainActor
class CheckoutViewModel: ObservableObject {
    // Cart
    @Published var cartItems: [CartItem] = CartItem.sampleItems
    
    // Shipping
    @Published var shippingAddress = PostalAddress()
    @Published var shippingMethod: ShippingMethod = .standard
    @Published var giftWrap = false
    @Published var giftMessage = ""
    
    // Payment
    @Published var cardNumber = ""
    @Published var cardHolderName = ""
    @Published var expiryDate = ""
    @Published var cvv = ""
    @Published var billingAddressSameAsShipping = true
    @Published var billingAddress = PostalAddress()
    
    // Review
    @Published var agreedToTerms = false
    @Published var subscribeToNewsletter = false
    
    // Order
    @Published var showOrderConfirmation = false
    @Published var orderNumber = ""
    
    // Validation
    @Published var cardNumberError: String?
    @Published var expiryError: String?
    @Published var cvvError: String?
    
    var subtotal: Double {
        cartItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var shippingCost: Double {
        shippingMethod.cost
    }
    
    var tax: Double {
        subtotal * 0.08
    }
    
    var total: Double {
        subtotal + shippingCost + tax + (giftWrap ? 5.99 : 0)
    }
    
    var isPaymentValid: Bool {
        validateCardNumber() && validateExpiry() && validateCVV()
    }
    
    func validateCardNumber() -> Bool {
        let digitsOnly = cardNumber.filter { $0.isNumber }
        return digitsOnly.count >= 15 && digitsOnly.count <= 16
    }
    
    func validateExpiry() -> Bool {
        let pattern = #"^(0[1-9]|1[0-2])\/([0-9]{2})$"#
        return expiryDate.range(of: pattern, options: .regularExpression) != nil
    }
    
    func validateCVV() -> Bool {
        let digitsOnly = cvv.filter { $0.isNumber }
        return digitsOnly.count >= 3 && digitsOnly.count <= 4
    }
    
    func removeItem(_ item: CartItem) {
        cartItems.removeAll { $0.id == item.id }
    }
    
    func updateQuantity(for item: CartItem, quantity: Int) {
        if let index = cartItems.firstIndex(where: { $0.id == item.id }) {
            if quantity <= 0 {
                cartItems.remove(at: index)
            } else {
                cartItems[index].quantity = quantity
            }
        }
    }
    
    func placeOrder() {
        orderNumber = String(format: "%08d", Int.random(in: 10000000...99999999))
        showOrderConfirmation = true
    }
    
    func reset() {
        cartItems = CartItem.sampleItems
        shippingAddress = PostalAddress()
        shippingMethod = .standard
        giftWrap = false
        giftMessage = ""
        cardNumber = ""
        cardHolderName = ""
        expiryDate = ""
        cvv = ""
        billingAddressSameAsShipping = true
        billingAddress = PostalAddress()
        agreedToTerms = false
        subscribeToNewsletter = false
    }
}

// MARK: - Cart Item Model

struct CartItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let price: Double
    var quantity: Int
    let imageSystemName: String
    
    static let sampleItems: [CartItem] = [
        CartItem(
            name: "Wireless Headphones",
            description: "Premium noise-canceling headphones",
            price: 299.99,
            quantity: 1,
            imageSystemName: "headphones"
        ),
        CartItem(
            name: "Smart Watch",
            description: "Fitness tracking smartwatch",
            price: 399.99,
            quantity: 1,
            imageSystemName: "applewatch"
        ),
        CartItem(
            name: "USB-C Cable",
            description: "Fast charging cable, 2m",
            price: 19.99,
            quantity: 2,
            imageSystemName: "cable.connector"
        )
    ]
}

// MARK: - Shipping Method

enum ShippingMethod: String, CaseIterable, Identifiable {
    case standard = "Standard Shipping"
    case express = "Express Shipping"
    case overnight = "Overnight Shipping"
    
    var id: String { rawValue }
    
    var cost: Double {
        switch self {
        case .standard: return 5.99
        case .express: return 14.99
        case .overnight: return 29.99
        }
    }
    
    var estimatedDays: String {
        switch self {
        case .standard: return "5-7 business days"
        case .express: return "2-3 business days"
        case .overnight: return "Next business day"
        }
    }
}

// MARK: - Cart Review Step

struct CartReviewStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Shopping Cart")
                .font(.title2.bold())
            
            if viewModel.cartItems.isEmpty {
                emptyCartView
            } else {
                ForEach(viewModel.cartItems) { item in
                    CartItemRow(item: item, viewModel: viewModel)
                }
                
                Divider()
                
                // Order summary
                VStack(spacing: 12) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.subtotal, format: .currency(code: "USD"))
                    }
                    
                    HStack {
                        Text("Shipping")
                        Spacer()
                        Text(viewModel.shippingCost, format: .currency(code: "USD"))
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(viewModel.tax, format: .currency(code: "USD"))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.total, format: .currency(code: "USD"))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Your cart is empty")
                .font(.headline)
            
            Text("Add some items to continue shopping")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Cart Item Row

struct CartItemRow: View {
    let item: CartItem
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Product image
            Image(systemName: item.imageSystemName)
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
                .frame(width: 60, height: 60)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.price, format: .currency(code: "USD"))
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            // Quantity stepper
            VStack(spacing: 8) {
                Stepper("", value: Binding(
                    get: { item.quantity },
                    set: { viewModel.updateQuantity(for: item, quantity: $0) }
                ), in: 0...99)
                .labelsHidden()
                
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Shipping Step

struct ShippingStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Shipping Address")
                .font(.title2.bold())
            
            // Address form
            FormAddressField(
                "",
                address: $viewModel.shippingAddress,
                configuration: AddressFieldConfiguration(
                    showStreet2: true,
                    showCountry: true,
                    enableAutocomplete: true
                )
            )
            
            Divider()
            
            // Shipping method
            Text("Shipping Method")
                .font(.headline)
            
            ForEach(ShippingMethod.allCases) { method in
                ShippingMethodRow(
                    method: method,
                    isSelected: viewModel.shippingMethod == method,
                    onSelect: { viewModel.shippingMethod = method }
                )
            }
            
            Divider()
            
            // Gift options
            Text("Gift Options")
                .font(.headline)
            
            Toggle("Gift wrap (+$5.99)", isOn: $viewModel.giftWrap)
            
            if viewModel.giftWrap {
                TextField("Gift message (optional)", text: $viewModel.giftMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...5)
            }
        }
    }
}

// MARK: - Shipping Method Row

struct ShippingMethodRow: View {
    let method: ShippingMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.rawValue)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(method.estimatedDays)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(method.cost, format: .currency(code: "USD"))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Payment Step

struct PaymentStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Payment Details")
                .font(.title2.bold())
            
            // Card number
            VStack(alignment: .leading, spacing: 4) {
                Text("Card Number")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.secondary)
                    
                    TextField("1234 5678 9012 3456", text: $viewModel.cardNumber)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.cardNumber) { newValue in
                            viewModel.cardNumber = formatCardNumber(newValue)
                        }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Card holder name
            VStack(alignment: .leading, spacing: 4) {
                Text("Cardholder Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    
                    TextField("John Doe", text: $viewModel.cardHolderName)
                        .autocapitalization(.words)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            // Expiry and CVV
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Expiry Date")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("MM/YY", text: $viewModel.expiryDate)
                        .keyboardType(.numberPad)
                        .onChange(of: viewModel.expiryDate) { newValue in
                            viewModel.expiryDate = formatExpiryDate(newValue)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CVV")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("123", text: $viewModel.cvv)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(width: 100)
            }
            
            Divider()
            
            // Billing address
            Toggle("Billing address same as shipping", isOn: $viewModel.billingAddressSameAsShipping)
            
            if !viewModel.billingAddressSameAsShipping {
                Text("Billing Address")
                    .font(.headline)
                    .padding(.top)
                
                FormAddressField(
                    "",
                    address: $viewModel.billingAddress
                )
            }
            
            // Security note
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                
                Text("Your payment information is secure and encrypted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func formatCardNumber(_ value: String) -> String {
        let digitsOnly = value.filter { $0.isNumber }
        let limited = String(digitsOnly.prefix(16))
        
        var result = ""
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 {
                result += " "
            }
            result.append(char)
        }
        return result
    }
    
    private func formatExpiryDate(_ value: String) -> String {
        let digitsOnly = value.filter { $0.isNumber }
        let limited = String(digitsOnly.prefix(4))
        
        if limited.count >= 3 {
            let month = String(limited.prefix(2))
            let year = String(limited.dropFirst(2))
            return "\(month)/\(year)"
        }
        return limited
    }
}

// MARK: - Order Review Step

struct OrderReviewStep: View {
    @ObservedObject var viewModel: CheckoutViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Your Order")
                .font(.title2.bold())
            
            // Order items
            GroupBox("Items") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.cartItems) { item in
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("\(item.quantity) × \(item.price, format: .currency(code: "USD"))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Shipping info
            GroupBox("Shipping") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.shippingAddress.formattedMultiLine)
                        .font(.body)
                    
                    Divider()
                    
                    HStack {
                        Text(viewModel.shippingMethod.rawValue)
                        Spacer()
                        Text(viewModel.shippingMethod.estimatedDays)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Payment info
            GroupBox("Payment") {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.accentColor)
                    
                    Text("•••• •••• •••• \(String(viewModel.cardNumber.suffix(4)))")
                    
                    Spacer()
                    
                    Text(viewModel.cardHolderName)
                        .foregroundColor(.secondary)
                }
            }
            
            // Order total
            GroupBox("Order Total") {
                VStack(spacing: 8) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(viewModel.subtotal, format: .currency(code: "USD"))
                    }
                    
                    HStack {
                        Text("Shipping")
                        Spacer()
                        Text(viewModel.shippingCost, format: .currency(code: "USD"))
                    }
                    
                    if viewModel.giftWrap {
                        HStack {
                            Text("Gift Wrap")
                            Spacer()
                            Text(5.99, format: .currency(code: "USD"))
                        }
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(viewModel.tax, format: .currency(code: "USD"))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text(viewModel.total, format: .currency(code: "USD"))
                            .font(.title3.bold())
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // Terms
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $viewModel.agreedToTerms) {
                    Text("I agree to the Terms of Service and Privacy Policy")
                        .font(.subheadline)
                }
                
                Toggle(isOn: $viewModel.subscribeToNewsletter) {
                    Text("Subscribe to newsletter for exclusive offers")
                        .font(.subheadline)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct CheckoutFormExample_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutFormExample()
    }
}
#endif
