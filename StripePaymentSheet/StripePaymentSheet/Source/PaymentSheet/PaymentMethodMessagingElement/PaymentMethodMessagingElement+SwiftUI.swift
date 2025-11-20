//
//  PaymentMethodMessagingElement+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/17/25.
//

import Combine
import Foundation
import SwiftUI
import UIKit

extension PaymentMethodMessagingElement {

    /// A SwiftUI View of the element.
    @available(iOS 15.0, *)
    public struct View<Content: SwiftUI.View>: SwiftUI.View {

        @State var phase: Phase = .loading
        let content: (Phase) -> Content
        let config: Configuration?
        let integrationType: PMMEAnalyticsHelper.IntegrationType

        /// Initializes a PaymentMethodMessagingElement SwiftUI View.
        /// During loading and in the case of no content being available to display, an invisible size 0 placeholder takes the place of the view.
        /// - Parameter config: Configuration for the PaymentMethodMessagingElement, such as the amount and currency of the purchase.
        public init(configuration: Configuration) where Content == AnyView {
            self.config = configuration
            self.content = { phase in
                if case .loaded(let view) = phase {
                    AnyView(view)
                } else {
                    AnyView(EmptyView())
                }
            }
            self.integrationType = .config
        }

        /// Initializes a PaymentMethodMessagingElement SwiftUI View.
        /// - Parameter config: Configuration for the PaymentMethodMessagingElement, such as the amount and currency of the purchase.
        /// - Parameter content: Content to be displayed depending on the element's current phase.
        public init(configuration: Configuration, @ViewBuilder content: @escaping (Phase) -> Content) {
            self.config = configuration
            self.content = content
            self.integrationType = .content
        }

        /// Initializes a PaymentMethodMessagingElement SwiftUI View.
        /// Use this initializer when you want manual control over the element creation or to initialize it outside of the UI layer.
        /// - Parameter viewData: The ViewData for a given configuration.
        public init(_ viewData: ViewData) where Content == AnyView {
            self.config = nil
            self.content = { _ in
                AnyView(PMMELoadedView(viewData: viewData, integrationType: .viewData))
            }
            self.integrationType = .viewData
        }

        public var body: some SwiftUI.View {
            bodyImpl()
        }
    }

    /// The phase of the Payment Method Messaging Element's loading process.
    @available(iOS 15.0, *)
    @frozen public enum Phase {
        /// The PaymentMethodMessagingElement is loading data from the Stripe backend.
        case loading
        /// The PaymentMethodMessagingElement was successfully loaded.
        /// - Parameter view: The created View for display.
        case loaded(view: AnyView)
        /// The configuration was successfully loaded, but there is no content available to display (for example because the amount is less than the minimum for available payment methods).
        case noContent
        /// The configuration failed to be loaded.
        /// - Parameter Error: An `Error` object representing the reason the element failed to load
        case failed(Error)
    }

    /// The element's view data for the SwiftUI view.
    public var viewData: ViewData {
        .init(mode: mode, infoUrl: infoUrl, promotion: promotion, appearance: appearance, analyticsHelper: analyticsHelper)
    }

    /// Displayable data of an initialized Payment Method Messaging Element.
    /// For use by PaymentMethodMessagingElement.View.
    public struct ViewData {
        let mode: Mode
        let infoUrl: URL
        let promotion: String
        let appearance: PaymentMethodMessagingElement.Appearance
        let analyticsHelper: PMMEAnalyticsHelper
    }
}
