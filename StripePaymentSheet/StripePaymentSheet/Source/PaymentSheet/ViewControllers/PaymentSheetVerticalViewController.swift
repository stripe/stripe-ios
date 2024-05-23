//
//  PaymentSheetVerticalViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/3/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetVerticalViewController: UIViewController, FlowControllerViewControllerProtocol, PaymentSheetViewControllerProtocol {
    var selectedPaymentOption: PaymentSheet.PaymentOption?
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType?
    let loadResult: PaymentSheetLoader.LoadResult
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let configuration: PaymentSheet.Configuration
    var intent: Intent {
        return loadResult.intent
    }
    var error: Error?
    private var savedPaymentMethods: [STPPaymentMethod]
    let isFlowController: Bool
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
    weak var paymentSheetDelegate: PaymentSheetViewControllerDelegate?

    private var accessoryButtonType: VerticalPaymentMethodListView.AccessoryButtonType {
        var buttonType: VerticalPaymentMethodListView.AccessoryButtonType = .none
        if savedPaymentMethods.count > 1 {
            buttonType = .viewMore
        } else if savedPaymentMethods.count == 1 && (savedPaymentMethods.first?.isCoBrandedCard ?? false) && loadResult.intent.cardBrandChoiceEligible {
            // If only one card left but it is co-branded we can edit it
            buttonType = .edit
        } else if savedPaymentMethods.count == 1 && configuration.allowsRemovalOfLastSavedPaymentMethod {
            // If only one payment method left and we can remove it we can edit
            buttonType = .edit
        }
        
        return buttonType
    }
    
    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

    lazy var paymentMethodListView: VerticalPaymentMethodListView = {
        return VerticalPaymentMethodListView(
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled,
            shouldShowLink: loadResult.isLinkEnabled,
            appearance: configuration.appearance,
            accessoryButtonType: accessoryButtonType,
            delegate: self
        )
    }()

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool) {
        // TODO: Deal with previousPaymentOption
        self.loadResult = loadResult
        self.configuration = configuration
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: loadResult.intent,
            configuration: configuration,
            logAvailability: false
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodListView,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: PaymentSheetUI.defaultSheetMargins.bottom, trailing: 0))
    }
}

// MARK: - BottomSheetContentViewController
extension PaymentSheetVerticalViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        // TODO
        return true
    }

    func didTapOrSwipeToDismiss() {
        // TODO
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

extension PaymentSheetVerticalViewController: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod]) {
        // TODO
        print("Selected payment method with id: \(String(describing: selectedPaymentMethod?.stripeId))")
        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        savedPaymentMethods = latestPaymentMethods
        
        paymentMethodListView.removeFromSuperview()
        paymentMethodListView = VerticalPaymentMethodListView(
            savedPaymentMethod: selectedPaymentMethod,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled,
            shouldShowLink: loadResult.isLinkEnabled,
            appearance: configuration.appearance,
            accessoryButtonType: accessoryButtonType,
            delegate: self
        )
        // TODO update selected payment method with `selectedPaymentMethod`
        // TODO update the accessory button
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewDelegate {
    func didSelectPaymentMethod(_ selection: VerticalPaymentMethodListView.Selection) {
        switch selection {
        case .applePay, .link, .new:
            // TODO
            return
        case .saved:
            // TODO
            return
        }
    }
    
    func didSelectAccessoryButton(_ type: VerticalPaymentMethodListView.AccessoryButtonType) {
        switch type {
        case .none:
            // no-op
            break
        case .edit:
            // TODO present update view controller
            break
        case .viewMore:
            let vc = VerticalSavedPaymentMethodsViewController(
                configuration: configuration,
                selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
                paymentMethods: savedPaymentMethods
            )
            vc.delegate = self
            bottomSheetController?.pushContentViewController(vc)
        }
    }
}

extension PaymentSheetVerticalViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO:
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO:
    }
}
