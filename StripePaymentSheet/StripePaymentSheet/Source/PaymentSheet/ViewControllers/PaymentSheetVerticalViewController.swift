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

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

    lazy var paymentMethodListViewController: VerticalPaymentMethodListViewController = {
        return VerticalPaymentMethodListViewController(
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled,
            shouldShowLink: loadResult.isLinkEnabled,
            appearance: configuration.appearance,
            delegate: self
        )
    }()

    var paymentMethodFormViewController: PaymentMethodFormViewController?

    lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
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
            paymentContainerView,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: PaymentSheetUI.defaultSheetMargins.bottom, trailing: 0))
        add(childViewController: paymentMethodListViewController, containerView: paymentContainerView)
    }

    // TOOD(porter) Remove/rename
    @objc func presentManageScreen() {
        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible
        )
        vc.delegate = self
        bottomSheetController?.pushContentViewController(vc)
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
        _ = viewController.bottomSheetController?.popContentViewController()
        // TODO update selected payment method with `selectedPaymentMethod`
    }
}

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
            let formFactory = PaymentSheetFormFactory(intent: intent, configuration: .paymentSheet(configuration), paymentMethod: paymentMethodType)
            let form = formFactory.make()
            if form.collectsUserInput {
                // The payment method form collects user input; display it
                let paymentMethodFormViewController = PaymentMethodFormViewController(form: form)
                self.paymentMethodFormViewController = paymentMethodFormViewController
#if !canImport(CompositorServices)
                UISelectionFeedbackGenerator().selectionChanged()
#endif
                // Return false so the payment method isn't selected in the list; this implicitly keeps the most recently selected payment method as selected.
                switchContentIfNecessary(to: paymentMethodFormViewController, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                return false
            } else {
                // Otherwise, return true so the payment method appears selected in the list
                return true
            }
        case .saved:
            presentManageScreen()
            return true
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
        switchContentIfNecessary(to: paymentMethodListViewController, containerView: paymentContainerView)
        navigationBar.setStyle(.close(showAdditionalButton: false))
    }
}
