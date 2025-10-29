//
//  PaymentSheetExampleAppRootView.swift
//  PaymentSheet Example
//

import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct PaymentSheetExampleAppRootView: View {
    private var destinationsBySection: [Section: [NavigationDestination]] {
        NavigationDestination.destinationsBySection
    }

    var body: some View {
        NavigationView {
            Form {
                ForEach(Section.allCases, id: \.self) { section in
                    SwiftUI.Section(section.rawValue) {
                        ForEach(destinationsBySection[section] ?? [], id: \.self) { destination in
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
        }
        .navigationTitle("Examples")
        .navigationBarTitleDisplayMode(.inline)
    }

    enum Section: String, CaseIterable {
        case testPlaygrounds = "Test Playgrounds"
        case examples = "Examples"
    }

    enum NavigationDestination: Hashable, CaseIterable {
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

        case paymentSheet_playground
        case customerSheet_playground

        static var destinationsBySection: [Section: [NavigationDestination]] {
            var result: [Section: [NavigationDestination]] = [:]

            for section in Section.allCases {
                result[section] = []
            }

            for destination in allCases {
                switch destination {
                case .paymentSheet,
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
                     .addressCollection_swiftUI:
                    result[.examples]?.append(destination)
                case .paymentSheet_playground,
                     .customerSheet_playground:
                    result[.testPlaygrounds]?.append(destination)
                }
            }

            return result
        }

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
            MyEmbeddedCheckoutView()
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
            CustomerSheetTestPlayground()
        case .paymentSheet_playground:
            PaymentSheetTestPlayground()
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
