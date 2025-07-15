//
//  PaymentSheetExampleAppRootView.swift
//  PaymentSheet Example
//

import StripePaymentSheet
import SwiftUI

@available(iOS 14.0, *)
struct PaymentSheetExampleAppRootView: View {

    private var exampleDestinations: [NavigationDestination] {
        [
            .paymentSheet,
            .paymentSheet_deferred,
            .paymentSheet_flowController,
            .paymentSheet_flowController_deferred,
            .paymentSheet_swiftUI,
            .paymentSheet_flowController_swiftUI,
            .customerSheet_swiftUI,
            .linkPaymentController,
            .linkController,
            .linkStandaloneDemo,
            .embeddedPaymentElement,
            .embeddedPaymentElement_swiftUI,
            .walletButtonsView_swiftUI,
        ]
    }

    private var playgroundDestinations: [NavigationDestination] {
        [
            .customerSheet_playground,
            .paymentSheet_playground,
        ]
    }

    var body: some View {
        if #available(iOS 15.0, *) {
            NavigationView {
                Form {
                    Section("Test Playgrounds") {
                        ForEach(playgroundDestinations, id: \.self) { destination in
                            NavigationLink(
                                destination: destinationView(for: destination)
                            ) {
                                Text(destination.displayTitle)
                            }
                            .accessibility(identifier: destination.displayTitle)
                        }
                    }

                    Section("Examples") {
                        ForEach(exampleDestinations, id: \.self) { destination in
                            NavigationLink(
                                destination: destinationView(for: destination)
                            ) {
                                Text(destination.displayTitle)
                            }
                            .accessibility(identifier: destination.displayTitle)
                        }
                    }
                }
            }
            .navigationTitle("Examples")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            Text("Sorry, only available on >= iOS 15.0")
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
        case linkController
        case linkStandaloneDemo
        case embeddedPaymentElement
        case embeddedPaymentElement_swiftUI
        case walletButtonsView_swiftUI
        case addressCollection_swiftUI

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
            case .linkController:
                return "LinkController (SwiftUI)"
            case .linkStandaloneDemo:
                return "Link Standalone Demo"
            case .embeddedPaymentElement:
                return "EmbeddedPaymentElement"
            case .embeddedPaymentElement_swiftUI:
                return "EmbeddedPaymentElement (SwiftUI)"
            case .walletButtonsView_swiftUI:
                return "WalletButtonsView (SwiftUI)"
            case .addressCollection_swiftUI:
                return "AddressElement (SwiftUI)"
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
        case .linkController:
            if #available(iOS 16.0, *) {
                ExampleLinkControllerView()
            } else {
                Text("Sorry, only available on >= iOS 16.0")
                    .font(.title2)
            }
        case .linkStandaloneDemo:
            if #available(iOS 16.0, *) {
                ExampleLinkStandaloneComponent()
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
        case .addressCollection_swiftUI:
            if #available(iOS 15.0, *) {
                AddressElementExampleView()
            } else {
                Text("Sorry, only available on >= iOS 15.0")
                    .font(.title2)
            }

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
}

@available(iOS 15.0, *)
struct PaymentSheetExampleAppRootView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentSheetExampleAppRootView()
    }
}
