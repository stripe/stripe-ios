//
//  EmbeddedPaymentElementController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/10/24.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

protocol EmbeddedPaymentElementControllerDelegate: AnyObject {
    func heightDidChange()
    func selectionDidChange()
    func willPresentForm()
}

class EmbeddedPaymentElementController {
    weak var presentingViewController: UIViewController?
    weak var delegate: EmbeddedPaymentElementControllerDelegate?

    private let configuration: EmbeddedPaymentElement.Configuration
    private let loadResult: PaymentSheetLoader.LoadResult
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private let formCache: PaymentMethodFormCache = .init()
    let embeddedPaymentMethodsView: EmbeddedPaymentMethodsView

    // TODO(porter) Do we need this?
    private var lastSeenPaymentOption: PaymentOption?

    var displayData: EmbeddedPaymentElement.PaymentOptionDisplayData? {
        embeddedPaymentMethodsView.displayData
    }

    private init(configuration: EmbeddedPaymentElement.Configuration,
                 loadResult: PaymentSheetLoader.LoadResult,
                 analyticsHelper: PaymentSheetAnalyticsHelper,
                 embeddedPaymentMethodsView: EmbeddedPaymentMethodsView) {
        self.configuration = configuration
        self.loadResult = loadResult
        self.analyticsHelper = analyticsHelper
        self.embeddedPaymentMethodsView = embeddedPaymentMethodsView
        self.embeddedPaymentMethodsView.delegate = self
    }

    static func create(intentConfiguration: PaymentSheet.IntentConfiguration,
                       configuration: EmbeddedPaymentElement.Configuration) async throws -> EmbeddedPaymentElementController {
        // TODO(porter) Should we create a new analytics helper specific to embedded? Figured this out when we do analytics.
        let analyticsHelper = PaymentSheetAnalyticsHelper(isCustom: true, configuration: PaymentSheet.Configuration())
        AnalyticsHelper.shared.generateSessionID()

        let loadResult = try await PaymentSheetLoader.load(mode: .deferredIntent(intentConfiguration),
                                                          configuration: configuration,
                                                          analyticsHelper: analyticsHelper,
                                                          integrationShape: .embedded)
        let shouldShowApplePay = PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let shouldShowLink = PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let savedPaymentMethodAccessoryType = await RowButton.RightAccessoryButton.getAccessoryButtonType(
           savedPaymentMethodsCount: loadResult.savedPaymentMethods.count,
           isFirstCardCoBranded: loadResult.savedPaymentMethods.first?.isCoBrandedCard ?? false,
           isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
           allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
           allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )

        let initialSelection: EmbeddedPaymentMethodsView.Selection? = {
           // Default to the customer's default or the first saved payment method, if any
           let customerDefault = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customer?.id)
           switch customerDefault {
           case .applePay:
               return .applePay
           case .link:
               return .link
           case .stripeId, nil:
               return loadResult.savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
           }
        }()

        let embeddedPaymentMethodsView = await EmbeddedPaymentMethodsView(
           initialSelection: initialSelection,
           paymentMethodTypes: loadResult.paymentMethodTypes,
           savedPaymentMethod: loadResult.savedPaymentMethods.first,
           appearance: configuration.appearance,
           shouldShowApplePay: shouldShowApplePay,
           shouldShowLink: shouldShowLink,
           savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
           mandateProvider: VerticalListMandateProvider(configuration: configuration,
                                                        elementsSession: loadResult.elementsSession,
                                                        intent: .deferredIntent(intentConfig: intentConfiguration)),
           shouldShowMandate: configuration.embeddedViewDisplaysMandateText
        )

        return .init(configuration: configuration, loadResult: loadResult, analyticsHelper: analyticsHelper, embeddedPaymentMethodsView: embeddedPaymentMethodsView)
    }
}

extension EmbeddedPaymentElementController: EmbeddedPaymentMethodsViewDelegate {
    func heightDidChange() {
        delegate?.heightDidChange()
    }

    func selectionTapped(didChange: Bool) {
        if didChange {
            delegate?.selectionDidChange()
        }

        guard case let .new(paymentMethodType) = embeddedPaymentMethodsView.selection else {
            return
        }

        guard let presentingVC = presentingViewController else {
            assertionFailure("Presenting view controller not found, set EmbeddedPaymentElement.presentingViewController.")
            return
        }

        let embeddedFormVC = EmbeddedFormViewController(
            configuration: configuration,
            loadResult: loadResult,
            paymentMethodType: paymentMethodType,
            previousPaymentOption: lastSeenPaymentOption,
            analyticsHelper: analyticsHelper,
            formCache: formCache
        )
        embeddedFormVC.delegate = self

        // Only show forms that require user input
        guard embeddedFormVC.collectsUserInput else { return }

        let bottomSheet = BottomSheetViewController(
            contentViewController: embeddedFormVC,
            appearance: configuration.appearance,
            isTestMode: configuration.apiClient.isTestmode,
            didCancelNative3DS2: {}
        )

        delegate?.willPresentForm()
        presentingVC.presentAsBottomSheet(bottomSheet, appearance: configuration.appearance)
    }
}

extension EmbeddedPaymentElementController: EmbeddedFormViewControllerDelegate {
    func embeddedFormViewControllerShouldConfirm(
        _ embeddedFormViewController: EmbeddedFormViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        // Implement confirmation logic here
    }

    func embeddedFormViewControllerDidFinish(
        _ embeddedFormViewController: EmbeddedFormViewController,
        result: PaymentSheetResult
    ) {
        embeddedFormViewController.dismiss(animated: true) {
            guard case let .confirm(completion) = self.configuration.formSheetAction else {
                return
            }
            completion(result)
        }
    }

    func embeddedFormViewControllerDidCancel(_ embeddedFormViewController: EmbeddedFormViewController) {
        self.lastSeenPaymentOption = embeddedFormViewController.selectedPaymentOption
        if embeddedFormViewController.selectedPaymentOption == nil {
            embeddedPaymentMethodsView.resetSelection()
        }
        embeddedFormViewController.dismiss(animated: true)
        // Optionally notify the completion handler
    }

    func embeddedFormViewControllerShouldClose(_ embeddedFormViewController: EmbeddedFormViewController) {
        self.lastSeenPaymentOption = embeddedFormViewController.selectedPaymentOption
        if embeddedFormViewController.selectedPaymentOption == nil {
            embeddedPaymentMethodsView.resetSelection()
        }
        embeddedFormViewController.dismiss(animated: true)
    }
}
