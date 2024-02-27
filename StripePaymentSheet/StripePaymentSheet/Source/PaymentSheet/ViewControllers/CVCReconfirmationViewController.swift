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

protocol CVCReconfirmationViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: CVCReconfirmationViewController)
}

class CVCReconfirmationViewController: UIViewController {

    weak var delegate: CVCReconfirmationViewControllerDelegate?

    private lazy var cvcFormElement: CVCRecollectionElement = {
        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: .stripe(.card),
            previousCustomerInput: nil)
        let cvcCollectionElement = formElement.makeCardCVCCollection(
            paymentMethod: paymentMethod,
            mode: .detailedWithInput,
            appearance: configuration.appearance)
        cvcCollectionElement.delegate = self
        return cvcCollectionElement
    }()

    // MARK: - Views
    private lazy var cvcFormElementView: UIView = {
        return cvcFormElement.view
    }()

    private lazy var cvcRecollectionContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .top)
        view.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        view.addPinnedSubview(cvcFormElementView)
        view.updateHeight()
        return view
    }()

    // MARK: - Internal Properties
    private let intent: Intent
    private let paymentMethod: STPPaymentMethod
    private let configuration: PaymentSheet.Configuration
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
        intent: Intent,
        paymentMethod: STPPaymentMethod,
        configuration: PaymentSheet.Configuration
    ) {
        self.intent = intent
        self.paymentMethod = paymentMethod
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        let stackView = UIStackView(arrangedSubviews: [
            cvcRecollectionContainerView,
        ])
        stackView.bringSubviewToFront(cvcRecollectionContainerView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        updateUI()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cvcFormElement.beginEditing()
    }

    private func updateUI() {
        if cvcFormElement.view !== cvcFormElementView {
            let oldView = cvcFormElementView
            let newView = cvcFormElement.view

            cvcRecollectionContainerView.addPinnedSubview(newView)
            cvcRecollectionContainerView.layoutIfNeeded()
            newView.alpha = 0

            animateHeightChange {
                self.cvcRecollectionContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                if oldView !== self.cvcFormElementView {
                    oldView.removeFromSuperview()
                }
            }
        }
    }

}
extension CVCReconfirmationViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}
