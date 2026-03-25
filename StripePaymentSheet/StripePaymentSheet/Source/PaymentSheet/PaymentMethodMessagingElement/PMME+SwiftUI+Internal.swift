//
//  PMME+SwiftUI+Internal.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/27/25.
//

import SwiftUI
import UIKit

// UIViewRepresentable wrapper for UIKit implementation of PMME
struct PMMEViewRepresentable: UIViewRepresentable {

    let viewData: PaymentMethodMessagingElement.ViewData
    let integrationType: PMMEAnalyticsHelper.IntegrationType
    let didUpdateHeight: (CGFloat) -> Void

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        createView(andAddTo: containerView)

        return containerView
    }

    // When SwiftUI updates the view with new viewdata, we replace the old PMMEUIView with a new one
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Remove old PMMEUIView
        uiView.subviews.first?.removeFromSuperview()

        // Replace with new one
        createView(andAddTo: uiView)
    }

    private func createView(andAddTo parentView: UIView) {
        let view = PMMEUIView(viewData: viewData, integrationType: integrationType, didUpdateHeight: didUpdateHeight)

        view.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(view)

        // We don't set the bottom constraint.
        // The PMMEUIView will report its height to SwiftUI via didUpdateHeight and SwiftUI will set the correct frame
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: parentView.topAnchor),
            view.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
        ])
    }
}

@available(iOS 15.0, *)
extension PaymentMethodMessagingElement {

    struct PMMELoadedView: SwiftUI.View {

        @State private var height: CGFloat = 0
        let viewData: ViewData
        let integrationType: PMMEAnalyticsHelper.IntegrationType

        public var body: some SwiftUI.View {
            // Have the PMMEUIView report back its height and set the frame to it
            PMMEViewRepresentable(
                viewData: viewData,
                integrationType: integrationType,
                didUpdateHeight: { newHeight in
                self.height = newHeight
            })
            .frame(height: height)
        }
    }
}

@available(iOS 15.0, *)
extension PaymentMethodMessagingElement.View {

    @ViewBuilder func bodyImpl() -> some View {
        ZStack {
            Color.clear.frame(width: 0, height: 0)
            content(phase)
        }
        // Anytime the config (if provided) changes we reload.
        // .task automatically manages the lifetime of the task to match the view.
        // In the config (no content) integration style, the content will be an clear size 0 view to start, this
        //      is necessary since an EmptyView will not enter the view hierarchy and thus .task has nothing to run on.
        .task(id: config) {
            await load()
        }
    }

    private func load() async {
        guard let config else { return }
        Task { @MainActor in
            let loadResult = await PaymentMethodMessagingElement.create(configuration: config)
            switch loadResult {
            case let .success(element):
                self.phase = .loaded(
                    view: AnyView(
                        PaymentMethodMessagingElement.PMMELoadedView(
                            viewData: element.viewData,
                            integrationType: integrationType
                        )
                    )
                )
            case .noContent:
                self.phase = .noContent
            case let .failed(error):
                self.phase = .failed(error)
            }
        }
    }
}
