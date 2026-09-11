// Copyright © 2026 Stripe, Inc. All rights reserved.

@_spi(STP) import StripeCore
import UIKit

/// Presents the standalone Link authentication flow.
@MainActor
final class LinkVerificationController {
    typealias CompletionBlock = (LinkVerificationResult) -> Void
    private var selfRetainer: LinkVerificationController?
    private let flowController: LinkAuthFlowViewController

    init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        configuration: PaymentElementConfiguration,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        flowController = LinkAuthFlowViewController(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel
        )
        configuration.style.configure(flowController)
    }

    func present(from presentingController: UIViewController, completion: @escaping CompletionBlock) {
        selfRetainer = self
        flowController.onFinish = { [weak self] result in
            guard let self else { return }
            self.flowController.dismiss(animated: true) {
                completion(result)
                self.selfRetainer = nil
            }
        }
        presentingController.present(flowController, animated: true)
    }
}
