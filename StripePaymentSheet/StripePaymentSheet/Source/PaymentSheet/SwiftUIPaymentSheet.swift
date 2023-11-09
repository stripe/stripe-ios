//
//  SwiftUIPaymentSheet.swift
//  StripePaymentSheet
//
//  Created by David Estes on 11/7/23.
//

import SwiftUI
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripePayments
import PassKit

// TODO: Write some tests with this too

extension STPPaymentMethodType: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return self.rawValue
    }
}

class PaymentSheetState: ObservableObject {
    class Card: ObservableObject {
        @Published var number: String = ""
        @Published var expiry: String = ""
        @Published var cvc: String = ""

        var brand: STPCardBrand {
            return STPCardValidator.brand(forNumber: number)
        }
        
        // TODO: Move this out
        var expiryStrings: (month: String, year: String)? {
            let numericInput = STPNumericStringValidator.sanitizedNumericString(for: expiry)
            let monthString = numericInput.stp_safeSubstring(to: 2)
            var yearString = numericInput.stp_safeSubstring(from: 2)

            // prepend "20" to ensure we provide a 4 digit year, this is to be consistent with Checkout
            if yearString.count == 2 {
                let centuryLeadingDigits = Int(
                    floor(Double(Calendar(identifier: .iso8601).component(.year, from: Date())) / 100)
                )

                yearString = "\(centuryLeadingDigits)\(yearString)"
            }

            if monthString.count == 2 && yearString.count == 4 {
                return (month: monthString, year: yearString)
            } else {
                return nil
            }
        }
        
        func makeParams() -> STPPaymentMethodCardParams {
            let params = STPPaymentMethodCardParams()
            params.number = number
            if let expiryStrings = expiryStrings,
                let month = Int(expiryStrings.month),
                let year = Int(expiryStrings.year) {
                params.expMonth = NSNumber(value: month)
                params.expYear = NSNumber(value: year)
            }
            params.cvc = cvc
            return params
        }
    }
    @Published var card: Card = .init()
    
    class BillingAddress: ObservableObject {
        @Published var country: String = (Locale.current.regionCode ?? "US")
        @Published var postal: String = ""
        
        func makeParams() -> STPPaymentMethodBillingDetails {
            let params = STPPaymentMethodBillingDetails()
            let address = STPPaymentMethodAddress()
            address.country = country
            address.postalCode = postal
            params.address = address
            return params
        }
    }
    @Published var billingAddress: BillingAddress = .init()

    class Giropay: ObservableObject {
        @Published var name: String = ""
    }
    @Published var giropay: Giropay = .init()
    
    @Published var selectedPaymentMethod: STPPaymentMethodType = .card
    
    func makeParams() throws -> STPPaymentMethodParams {
        // TODO: Throw when validation fails, with useful human-readable error
        let params = STPPaymentMethodParams(type: selectedPaymentMethod)
        switch selectedPaymentMethod {
        case .card:
            params.card = card.makeParams()
        default:
            fatalError()
        }
        params.billingDetails = billingAddress.makeParams()
        return params
    }
}

@_spi(STP) public struct SwiftUIPaymentSheet: View {
    @StateObject private var state = PaymentSheetState()
    @State private var isLoaded = false
    var paymentSheet: PaymentSheet
    @State var intent: Intent?
    @_spi(STP) public init(paymentSheet: PaymentSheet) {
        self.paymentSheet = paymentSheet
    }
    
    @_spi(STP) public var body: some View {
        if isLoaded, let intent = intent {
            SwiftUIPaymentSheetInternal(paymentSheet: paymentSheet, intent: intent)
        } else {
            ProgressView()
                .onAppear {
                    PaymentSheetLoader.load(
                        mode: paymentSheet.mode,
                        configuration: paymentSheet.configuration
                    ) { loadingResult in 
                        switch loadingResult {
                        case .success(let intent, _, _):
                            self.intent = intent
                        case .failure(let error):
                            // Communicate error
                            print(error)
                            break
                        }
                        isLoaded = true
                    }
                }
        }
    }
}

@_spi(STP) public struct SwiftUIPaymentSheetInternal: View {
    @StateObject private var state = PaymentSheetState()
    var paymentSheet: PaymentSheet
    var intent: Intent
    @State var done: Bool = false
    @State var loading: Bool = false

    @_spi(STP) public var body: some View {
        VStack {
            if #available(iOS 16.0, *) {
                PayWithApplePayButton {
                    // pay
                }.frame(maxHeight: 46)
                .padding(20)
            }
            HStack {
                VStack {
                    Divider()
                }
                Text("Or pay using")
                    .font(.subheadline)
                    .foregroundColor(.init(.systemGray))
                VStack {
                    Divider()
                }
            }
            .padding([.bottom, .horizontal], 20)
            PaymentMethodTabView(state: state)
                .padding([.bottom], 10)
            switch state.selectedPaymentMethod {
                case .card:
                VStack {
                    CardView(card: state.card).padding([.horizontal], 20)
                    BillingView(billingAddress: state.billingAddress).padding([.horizontal], 20)
                }                        .transition(AnyTransition.opacity.combined(with: .slide))
                case .giropay:
                VStack {
                    GiropayView(giropay: state.giropay).padding([.horizontal], 20)
                    BillingView(billingAddress: state.billingAddress).padding([.horizontal], 20)
                }                        .transition(AnyTransition.opacity.combined(with: .slide))
                default:
                Text("Not yet supported.")
                    .transition(AnyTransition.opacity.combined(with: .slide))
            }
            Spacer()
            Button {
                // Confrim PaymentIntent with PaymentSheet
                switch intent {
                case .paymentIntent(_, let paymentIntent):
                    let intentParams = STPPaymentIntentParams(clientSecret: paymentIntent.clientSecret)
                    do {
                        intentParams.paymentMethodParams = try state.makeParams()
                    } catch {
                        // Show the error in the sheet
                    }
                    withAnimation {
                        self.loading = true
                    }
                    STPPaymentHandler.sharedHandler.confirmPayment(intentParams, with: SwiftUIAuthenticationContext().makeCoordinator()) { status, _, _ in
                        withAnimation {
                            self.loading = false
                            self.done = true
                        }
                        print(paymentIntent.stripeId)
                    }

                    
                case .setupIntent(_):
                    assertionFailure()
                case .deferredIntent(elementsSession: _, intentConfig: _):
                    assertionFailure()
                }
            } label: {
                if loading {
                    ProgressView()
                } else {
                    if done {
                        DoneView()
                    } else {
                        ExamplePaymentButtonView()
                    }
                }
            }

        }
        
    }
}

struct SwiftUIAuthenticationContext: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, STPAuthenticationContext {
        func authenticationPresentingViewController() -> UIViewController {
            // TODO: Find a real UIViewController
            return UIViewController()
        }
        var parent: SwiftUIAuthenticationContext
        
        init(parent: SwiftUIAuthenticationContext) {
            self.parent = parent
        }
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
    
    typealias UIViewControllerType = UIViewController
    
    
}

struct ExamplePaymentButtonView: View {
    var body: some View {
        HStack {
            Text("Pay $10.99").fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundColor(.white)
        .background(Color.blue)
        .cornerRadius(6)
        .padding(20)
        .accessibility(identifier: "Buy button")
    }
}

struct DoneView: View {
    var body: some View {
        HStack {
            SwiftUI.Image(systemName: "checkmark")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .foregroundColor(.white)
        .background(Color.green)
        .cornerRadius(6)
        .padding(20)
        .accessibility(identifier: "Buy button")
    }
}



extension PaymentSheetTypes {
    class Afterpay {
        
        struct State {
            var name: String
        }
        
        struct SheetView: View {
            var paymentSheetConfig: PaymentSheet.Configuration
            @State var paymentSheetConfig: PaymentSheet.Configuration
            
            var body: some View {
                VStack {
                    PaymentSheetGroup(title: "Afterpay") {
                        AfterPayHeader(config: config)
                        if config.isSettingUp {
                            MandateText(config: config)
                        }
                    }
                    BillingAddress(config: config, pmRequiresBillingName: true)
                }
            }
        }
    }
}




struct PaymentMethodTabView: View {
    @ObservedObject var state: PaymentSheetState
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(STPPaymentMethodType.allCases) { paymentMethodType in
                    if let image = paymentMethodType.makeImage() {
                        PaymentMethodCell(paymentMethodType: paymentMethodType, image: image)
                            .foregroundColor(state.selectedPaymentMethod == paymentMethodType ? .blue : .black)
                        .frame(minWidth: 100)
                        .onTapGesture {
                            withAnimation(.snappy) {
                                state.selectedPaymentMethod = paymentMethodType
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(state.selectedPaymentMethod == paymentMethodType ? Color.blue : Color.gray, lineWidth: state.selectedPaymentMethod == paymentMethodType ? 2 : 1)
                                .shadow(color: .init(white: 0, opacity: 0.15), radius: 4, x: 0, y: 2)
                        )
                        .padding(2) // For the overlay and shadow
                    }
                }
            }
            .padding([.leading], 18) // a little extra offset to match the above 20. a hack for now.
        }
    }

}

struct PaymentMethodCell: View {
    let paymentMethodType: STPPaymentMethodType
    let image: UIImage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                SwiftUI.Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .padding([.bottom], 2)
                Text("\(paymentMethodType.displayName)")
                    .font(.footnote)
                    .fontWeight(.medium)
            }
            .padding(11)
            Spacer()
        }
    }
    
}

let defaultAppearance = {
    let config = PaymentSheet.Configuration()
    return config.appearance
}()

struct CardTitleView: View {
    @ObservedObject var card: PaymentSheetState.Card
    
    var body: some View {
        VStack {
            Text("CardNumber \(card.number)")
//            SUICardBrandView(brand: card.brand)
        }
        
    }
}

struct CardView: View {
    @ObservedObject var card: PaymentSheetState.Card
    
    var body: some View {
        VStack {
            HStack {
                Text("Card information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Spacer()
            }
            VStack {
                PanTextView(pan: $card.number)
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding()
                Divider()
                HStack() {
                    TextField("MM / YY", text: $card.expiry)
                        .padding()
                    Divider()
                    TextField("CVC", text: $card.cvc)
                        .padding()
                }.fixedSize(horizontal: false, vertical: true)
            }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 1)
                        .shadow(color: .init(white: 0, opacity: 0.15), radius: 4, x: 0, y: 2)
                )

        }
    }
}

struct BillingView: View {
    @ObservedObject var billingAddress: PaymentSheetState.BillingAddress
    
    var body: some View {
        VStack {
            HStack {
                Text("Billing address")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                Spacer()
            }
            VStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Country or region")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    HStack {
                        Picker("Country or region", selection: $billingAddress.country, content: {
                            ForEach(Locale.isoRegionCodes, id: \.self, content: { country in
                                Text(Locale.current.localizedString(forRegionCode: country) ?? country)
                            })
                        }).accentColor(.black)
                        Spacer()
                    }
                }
                    .padding()
                Divider()
                TextField("Postal code", text: $billingAddress.postal)
                    .padding()
            }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray, lineWidth: 1)
                        .shadow(color: .init(white: 0, opacity: 0.15), radius: 4, x: 0, y: 2)
                )

        }
    }
}


struct GiropayView: View {
    @ObservedObject var giropay: PaymentSheetState.Giropay
    
    var body: some View {
        VStack {
            TextField("Name", text: $giropay.name)
        }
        
    }
}


struct SUICardBrandView: UIViewRepresentable {
    var brand: STPCardBrand
    
    func makeUIView(context: Context) -> CardBrandView {
        return CardBrandView()
    }

    func updateUIView(_ uiView: CardBrandView, context: Context) {
        uiView.cardBrand = brand
    }
}

// this almost worked!
//
//struct PanTextView: UIViewRepresentable {
//    @Binding var pan: String
//    
//    func makeUIView(context: Context) -> UIView {
//        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(defaultValue: pan,
//                                                                                       cardBrandDropDown: nil), theme: .default) { field, params in
////            cardParams(for: params).number = field.text
//            return params
//            }
//        let view = panElement.view
//        view.autoresizingMask = [.flexibleWidth]
//        view.translatesAutoresizingMaskIntoConstraints = true
//        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        view.setContentHuggingPriority(.required, for: .vertical)
//        return panElement.view
//    }
//        
//        
//    func updateUIView(_ uiView: UIView, context: Context) {
////        uiView.text = pan
//    }
//}

struct PanTextView: UIViewRepresentable {

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PanTextView
        
        init(parent: PanTextView) {
            self.parent = parent
        }
        
        @objc func textFieldDidChange(textField: UITextField) {
            self.parent.pan = textField.text ?? ""
        }
        
    }
    @Binding var pan: String

    func makeUIView(context: Context) -> STPCardNumberInputTextField {
        let view = STPCardNumberInputTextField()
//        let panElement = PaymentMethodElementWrapper(TextFieldElement.PANConfiguration(defaultValue: pan,
//                                                                                       cardBrandDropDown: nil), theme: .default) { field, params in
////            cardParams(for: params).number = field.text
//            return params
//            }
        view.delegate = context.coordinator
        view.autoresizingMask = [.flexibleWidth]
        view.translatesAutoresizingMaskIntoConstraints = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.required, for: .vertical)
        view.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(textField:)), for: .editingChanged)
        return view
    }


    func updateUIView(_ uiView: STPCardNumberInputTextField, context: Context) {
        uiView.text = pan
    }
}

//#Preview {
//    return SwiftUIPaymentSheet(paymentSheet: <#PaymentSheet#>)
//}
