//
//  LinkVerificationController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/// Presents the standalone Link authentication flow.
@MainActor
final class LinkVerificationController {
    typealias CompletionBlock = (LinkVerificationResult) -> Void
    private var selfRetainer: LinkVerificationController?
    private let flowController: LinkAuthFlowViewController
    private var isDismissingAttached = false

    init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        configuration: PaymentElementConfiguration,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil,
        analyticsHelper: LinkAnalyticsHelper
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        flowController = LinkAuthFlowViewController(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel,
            analyticsHelper: analyticsHelper
        )
        configuration.style.configure(flowController)
    }

    /// Presents an attempt that another host owns; see `LinkAuthFlowViewController(sharedCoordinator:…)`.
    /// The host forwards the coordinator's callbacks through the `coordinatorDid…` methods.
    init(
        mode: LinkVerificationView.Mode = .modal,
        sharedCoordinator coordinator: LinkAuthFlowCoordinator,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        configuration: PaymentElementConfiguration,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false
    ) {
        LinkUI.applyLiquidGlassIfPossible(configuration: configuration)
        flowController = LinkAuthFlowViewController(
            mode: mode,
            sharedCoordinator: coordinator,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog
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

    enum AttachedOutcome {
        /// The shared attempt finished while the dialog was showing.
        case finished(LinkVerificationResult)
        /// The customer closed the dialog. The shared attempt continues.
        case detached
    }

    /// Presents a controller created with a shared coordinator. Completion runs after the dialog dismisses.
    func presentAttached(from presentingController: UIViewController, completion: @escaping (AttachedOutcome) -> Void) {
        selfRetainer = self
        flowController.onFinish = { [weak self] result in
            self?.dismiss(with: .finished(result), completion: completion)
        }
        flowController.onDetachRequested = { [weak self] in
            self?.dismiss(with: .detached, completion: completion)
        }
        presentingController.present(flowController, animated: true)
    }

    /// Dismisses an attached dialog on the host's behalf, e.g. when the host goes away.
    func detach(completion: @escaping (AttachedOutcome) -> Void) {
        dismiss(with: .detached, completion: completion)
    }

    func coordinatorDidUpdate() {
        flowController.coordinatorDidUpdate()
    }

    func coordinatorDidFinish(_ result: LinkVerificationResult) {
        flowController.coordinatorDidFinish(result)
    }

    func coordinatorDidRequestWebHandoff(_ url: URL) {
        flowController.coordinatorDidRequestWebHandoff(url)
    }

    private func dismiss(with outcome: AttachedOutcome, completion: @escaping (AttachedOutcome) -> Void) {
        // Only the first of finish, detach, or a host-driven dismissal completes the presentation.
        guard selfRetainer != nil, !isDismissingAttached else { return }
        isDismissingAttached = true
        flowController.onFinish = nil
        flowController.onDetachRequested = nil
        flowController.dismiss(animated: true) {
            completion(outcome)
            self.selfRetainer = nil
        }
    }
}
