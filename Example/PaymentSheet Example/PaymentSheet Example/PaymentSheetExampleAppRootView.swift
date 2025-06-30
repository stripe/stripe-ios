//
//  PaymentSheetExampleAppRootView.swift
//  PaymentSheet Example
//

import SwiftUI

@available(iOS 15.0, *)
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
            // This is the staticText that XCUITest will find and tap
            Text(destination.displayTitle)
                .foregroundColor(.blue)
                .padding(.bottom, Constants.bottomPadding)
                .accessibility(identifier: destination.displayTitle)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedDestination = destination
                }
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
        case .embeddedPaymentElement:
            StoryboardSceneView<ExampleEmbeddedElementCheckoutViewController>(sceneIdentifier: "ExampleEmbeddedElementCheckoutViewController")

        case .embeddedPaymentElement_swiftUI:
            MyEmbeddedCheckoutView()
        case .walletButtonsView_swiftUI:
            ExampleWalletButtonsContainerView()

        // Playgrounds
        case .customerSheet_playground:
            CustomerSheetTestPlayground(settings: CustomerSheetTestPlaygroundController.settingsFromDefaults() ?? .defaultValues())
        case .paymentSheet_playground:
            PaymentSheetTestPlayground(settings: PlaygroundController.settingsFromDefaults() ?? .defaultValues())
        case .none:
            EmptyView()
        }
    }
}

@available(iOS 15.0, *)
struct PaymentSheetExampleAppRootView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetExampleAppRootView()
    }
}
