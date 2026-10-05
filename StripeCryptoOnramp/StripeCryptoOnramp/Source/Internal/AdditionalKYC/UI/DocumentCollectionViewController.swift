//
//  DocumentCollectionViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Hosts a document collection step and cleans up its work when the customer leaves it.
class DocumentCollectionViewController<Content: View>: UIHostingController<Content> {
    private let onLeave: () -> Void
    private var isLeaving = false

    /// Creates a navigation step using the flow's appearance.
    /// - Parameters:
    ///   - rootView: The content displayed by this step.
    ///   - appearance: The interface style applied to the hosting controller.
    ///   - onLeave: Cleanup performed after a pop or dismissal, but not when presenting a picker or pushing another step.
    init(rootView: Content, appearance: LinkAppearance, onLeave: @escaping () -> Void = {}) {
        self.onLeave = onLeave
        super.init(rootView: rootView)
        appearance.applyInterfaceStyle(to: self)
    }

    // MARK: - NSCoding

    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isLeaving = false

        // Without Liquid Glass, omit the preceding screen's title from the back button, leaving just the "<" to match designs.
        if !LiquidGlassDetector.isEnabledInMerchantApp,
           let controllers = navigationController?.viewControllers,
           let index = controllers.firstIndex(of: self), index > 0 {
            controllers[index - 1].navigationItem.backButtonDisplayMode = .minimal
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // A picker can cover this screen without ending collection. Only a navigation pop or dismissal ends it.
        isLeaving = isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isLeaving {
            // Prevent in-flight uploads and late picker callbacks from changing the closed flow.
            onLeave()
        }
    }
}
