//
//  CVCReconfirmationViewController.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class CVCReconfirmationViewController: UIViewController {
    let onCompletion: ((CVCReconfirmationViewController, IntentConfirmParams?) -> Void)
    let onCancel: ((CVCReconfirmationViewController) -> Void)

    // MARK: - Views
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = String.Localized.confirm_your_cvc
        return header
    }()
    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: .custom(title: String.Localized.confirm),
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapConfirmButton()
            }
        )
        return button
    }()

    lazy var cvcFormElement: CVCRecollectionElement = {
        let cvcCollectionElement = CVCRecollectionElement(
            paymentMethod: paymentMethod,
            mode: .detailedWithInput,
            appearance: configuration.appearance)
        cvcCollectionElement.delegate = self
        return cvcCollectionElement
    }()

    // MARK: - Internal Properties
    private let intent: Intent
    private let paymentMethod: STPPaymentMethod
    private let configuration: PaymentElementConfiguration
    private let cardBrand: STPCardBrand
    private var isPaymentInFlight: Bool = false
    var paymentOptionIntentConfirmParams: IntentConfirmParams? {
        let params = IntentConfirmParams(type: .stripe(.card))
        if let updatedParams = cvcFormElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        paymentMethod: STPPaymentMethod,
        intent: Intent,
        configuration: PaymentElementConfiguration,
        onCompletion: @escaping ((CVCReconfirmationViewController, IntentConfirmParams?) -> Void),
        onCancel: @escaping((CVCReconfirmationViewController) -> Void)
    ) {
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        self.onCompletion = onCompletion
        self.onCancel = onCancel
        self.cardBrand = paymentMethod.card?.brand ?? .unknown
        self.intent = intent
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setStyle(.close(showAdditionalButton: false))
        self.view.backgroundColor = configuration.appearance.colors.background
        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            cvcFormElement.view,
            confirmButton,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = 10
        stackView.axis = .vertical
        stackView.setCustomSpacing(16, after: headerLabel)
        stackView.setCustomSpacing(32, after: cvcFormElement.view)
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        // Get our margins in order
        view.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cvcFormElement.beginEditing()
    }

    private func updateUI() {
        updateButton()
    }

    func updateButton() {
        let state: ConfirmButton.Status = {
            if isPaymentInFlight {
                return .processing
            }
            return paymentOptionIntentConfirmParams == nil ? .disabled : .enabled
        }()

        confirmButton.update(
            state: state,
            animated: true
        )
    }

    @objc
    private func didTapConfirmButton() {
        updateUI()
        // TODO: Analytics
        onCompletion(self, paymentOptionIntentConfirmParams)
    }

}
extension CVCReconfirmationViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        updateUI()
    }

    func didUpdate(element: Element) {
        updateUI()
    }
}

extension CVCReconfirmationViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        return false
    }

    func didTapOrSwipeToDismiss() {
        // Users may be attempting to double tap "done", and may actually dismiss the sheet.
        // Therefore, do not dismiss sheet if customer taps the scrim
    }
}

extension CVCReconfirmationViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        onCancel(self)
    }
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // No-op
    }
}
