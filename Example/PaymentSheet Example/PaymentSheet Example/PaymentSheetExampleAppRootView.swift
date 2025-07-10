//
//  PaymentSheetExampleAppRootView.swift
//  PaymentSheet Example
//

import StripePaymentSheet
import SwiftUI

@available(iOS 14.0, *)
struct PaymentSheetExampleAppRootView: View {

    private struct Constants {
        static let bottomPadding: CGFloat = 15.0
    }
    @State private var selectedDestination: NavigationDestination?

    var body: some View {
        NavigationView  {
            VStack {
                Spacer()
                Text("Examples")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, Constants.bottomPadding)
                destinationLink(for: .paymentSheet)
                destinationLink(for: .paymentSheet_deferred)
                destinationLink(for: .paymentSheet_flowController)
                destinationLink(for: .paymentSheet_flowController_deferred)
                destinationLink(for: .paymentSheet_swiftUI)
                destinationLink(for: .paymentSheet_flowController_swiftUI)

                destinationLink(for: .customerSheet_swiftUI)
                destinationLink(for: .linkPaymentController)
                destinationLink(for: .linkStandaloneComponent)
                destinationLink(for: .linkAuthenticationController)
                destinationLink(for: .embeddedPaymentElement)
                destinationLink(for: .embeddedPaymentElement_swiftUI)
                destinationLink(for: .walletButtonsView_swiftUI)

                Text("Test Playgrounds")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.bottom, Constants.bottomPadding)
                destinationLink(for: .customerSheet_playground)
                destinationLink(for: .paymentSheet_playground)
                Spacer()
            }
        }
    }

    @ViewBuilder
    func destinationLink(for destination: NavigationDestination) -> some View {
        ZStack(alignment: .leading) {
            PressableTextLink(
                text: destination.displayTitle,
                bottomPadding: Constants.bottomPadding,
                destination: destination,
                selection: $selectedDestination
            )
            .accessibility(identifier: destination.displayTitle)
            .zIndex(1)

            // Hidden NavigationLink to handle the actual navigation
            NavigationLink(
                destination: destinationView(for: destination),
                tag: destination,
                selection: $selectedDestination
            ) { EmptyView() }
                .opacity(0)
                .frame(width: 0, height: 0)
        }
    }

    enum NavigationDestination: Hashable {
        case paymentSheet
        case paymentSheet_deferred
        case paymentSheet_flowController
        case paymentSheet_flowController_deferred
        case paymentSheet_swiftUI
        case paymentSheet_flowController_swiftUI

        case customerSheet_swiftUI
        case linkPaymentController
        case linkStandaloneComponent
        case linkAuthenticationController
        case embeddedPaymentElement
        case embeddedPaymentElement_swiftUI
        case walletButtonsView_swiftUI

        case customerSheet_playground
        case paymentSheet_playground
        var displayTitle: String {
            switch self {
            case .paymentSheet:
                return "PaymentSheet"
            case .paymentSheet_deferred:
                return "PaymentSheet (Deferred)"
            case .paymentSheet_flowController:
                return "PaymentSheet.FlowController"
            case .paymentSheet_flowController_deferred:
                return "PaymentSheet.FlowController (Deferred)"
            case .paymentSheet_swiftUI:
                return "PaymentSheet (SwiftUI)"
            case .paymentSheet_flowController_swiftUI:
                return "PaymentSheet.FlowController (SwiftUI)"

            case .customerSheet_swiftUI:
                return "CustomerSheet (SwiftUI)"
            case .linkPaymentController:
                return "LinkPaymentController"
            case .linkStandaloneComponent:
                return "Link Standalone Component"
            case .linkAuthenticationController:
                return "Link Authentication Controller"
            case .embeddedPaymentElement:
                return "EmbeddedPaymentElement"
            case .embeddedPaymentElement_swiftUI:
                return "EmbeddedPaymentElement (SwiftUI)"
            case .walletButtonsView_swiftUI:
                return "WalletButtonsView (SwiftUI)"
            case .customerSheet_playground:
                return "Customer Sheet (test playground)"
            case .paymentSheet_playground:
                return "Payment Sheet (test playground)"
            }
        }

    }

    @ViewBuilder
    func destinationView(for destination: NavigationDestination?) -> some View {
        switch destination {
        // Examples
        case .paymentSheet:
            StoryboardSceneView<ExampleCheckoutViewController>(sceneIdentifier: "ExampleCheckoutViewController")
        case .paymentSheet_deferred:
            StoryboardSceneView<ExampleDeferredCheckoutViewController>(sceneIdentifier: "ExampleDeferredCheckoutViewController")
        case .paymentSheet_flowController:
            StoryboardSceneView<ExampleCustomCheckoutViewController>(sceneIdentifier: "ExampleCustomCheckoutViewController")
        case .paymentSheet_flowController_deferred:
            StoryboardSceneView<ExampleCustomDeferredCheckoutViewController>(sceneIdentifier: "ExampleCustomDeferredCheckoutViewController")

        case .paymentSheet_swiftUI:
            ExampleSwiftUIPaymentSheet()
        case .paymentSheet_flowController_swiftUI:
            ExampleSwiftUICustomPaymentFlow()
        case .customerSheet_swiftUI:
            ExampleSwiftUICustomerSheet()

        case .linkPaymentController:
            StoryboardSceneView<ExampleLinkPaymentCheckoutViewController>(sceneIdentifier: "ExampleLinkPaymentCheckoutViewController")
        case .linkStandaloneComponent:
            if #available(iOS 16.0, *) {
                ExampleLinkStandaloneComponent()
            } else {
                Text("Sorry, only available on >= iOS 16.0")
                    .font(.title2)
            }
        case .linkAuthenticationController:
            if #available(iOS 16.0, *) {
                ExampleLinkAuthenticationController()
            } else {
                Text("Sorry, only available on >= iOS 16.0")
                    .font(.title2)
            }
        case .embeddedPaymentElement:
            StoryboardSceneView<ExampleEmbeddedElementCheckoutViewController>(sceneIdentifier: "ExampleEmbeddedElementCheckoutViewController")

        case .embeddedPaymentElement_swiftUI:
            if #available(iOS 15.0, *) {
                MyEmbeddedCheckoutView()
            } else {
                Text("Sorry, only available on >= iOS 15.0")
                    .font(.title2)
            }
        case .walletButtonsView_swiftUI:
            ExampleWalletButtonsContainerView()

        // Playgrounds
        case .customerSheet_playground:
            if #available(iOS 15.0, *) {
                CustomerSheetTestPlayground(settings: CustomerSheetTestPlaygroundController.settingsFromDefaults() ?? .defaultValues())
            } else {
                Text("Sorry, only available on >= iOS 15.0")
                    .font(.title2)
            }
        case .paymentSheet_playground:
            if #available(iOS 15.0, *) {
                PaymentSheetTestPlayground(settings: PlaygroundController.settingsFromDefaults() ?? .defaultValues(), appearance: PaymentSheet.Appearance.default)
            } else {
                Text("Sorry, only available on >= iOS 15.0")
                    .font(.title2)
            }
        case .none:
            EmptyView()
        }
    }

    struct PressableTextLink: View {
        let text: String
        let bottomPadding: CGFloat
        let destination: NavigationDestination
        @Binding var selection: NavigationDestination?

        @GestureState private var isPressed = false
        @State private var isTouchInside = false

        var body: some View {
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    Text(text)
                        .foregroundColor(isPressed && isTouchInside ? .blue.opacity(0.6) : .blue)
                        .padding(.bottom, bottomPadding)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isPressed) { _, state, _ in
                                    state = true
                                }
                                .onChanged { value in
                                    // Check if touch is within bounds
                                    let isInBounds = geometry.frame(in: .local).contains(value.location)
                                    withAnimation(.easeOut(duration: 0.05)) {
                                        isTouchInside = isInBounds
                                    }
                                }
                                .onEnded { value in
                                    // Only navigate if finger was inside when lifted
                                    let isInBounds = geometry.frame(in: .local).contains(value.location)
                                    if isInBounds {
                                        selection = destination
                                    }
                                    isTouchInside = false
                                }
                        )
                        .animation(.easeOut(duration: 0.05), value: isPressed)
                    Spacer()
                }
            }
            // Provide a reasonable size
            .frame(height: 20 + bottomPadding) // Adjust based on your text size
        }
    }
}

@available(iOS 15.0, *)
struct PaymentSheetExampleAppRootView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetExampleAppRootView()
    }
}
