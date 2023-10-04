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

    private lazy var cvcFormElement: PaymentMethodElement = {
        let formElement = PaymentSheetFormFactory(
            intent: intent,
            configuration: .paymentSheet(configuration),
            paymentMethod: .card,
            previousCustomerInput: nil)
        let cvcCollectionElement = formElement.makeCardCVCCollection()
        cvcCollectionElement.delegate = self
        return cvcCollectionElement
    }()

    private lazy var cvcRecollectionElement: CVCRecollectionElement? = {
        if let cvc = cvcFormElement.getAllSubElements().first(where: { ($0 as? CVCRecollectionElement) != nil}) as? CVCRecollectionElement {
            return cvc
        }
        return nil
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
    private let configuration: PaymentSheet.Configuration
    private let intent: Intent

    var paymentOptionIntentConfirmParams: IntentConfirmParams? {
        //TODO: Dont hard cdoe this
        let params = IntentConfirmParams(type: .card)
        if let updatedParams = cvcFormElement.updateParams(params: params) {
            return updatedParams
        }
        return nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        brand: STPCardBrand,
        intent: Intent,
        configuration: PaymentSheet.Configuration
    ) {
        self.configuration = configuration
        self.intent = intent
        super.init(nibName: nil, bundle: nil)
        updateUI()
        updateBrand(brand: brand)
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

    private func updateBrand(brand: STPCardBrand) {
        if let cvcRecollectionElement = self.cvcRecollectionElement {
            cvcRecollectionElement.didUpdateCardBrand(updatedCardBrand: brand)
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
