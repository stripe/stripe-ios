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
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        // TODO: set navBar.delegate = self
        return navBar
    }()

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool) {
        // TODO: Deal with previousPaymentOption
        self.loadResult = loadResult
        self.configuration = configuration
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
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

        let dummyButton = UIButton(type: .system)
        dummyButton.setTitle("Welcome to vertical mode", for: .normal)
        dummyButton.addTarget(self, action: #selector(presentManageScreen), for: .touchUpInside)

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            dummyButton,
        ])
        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: 0, trailing: PaymentSheetUI.defaultSheetMargins.bottom))
    }

    // TOOD(porter) Remove/rename
    @objc func presentManageScreen() {
        let vc = VerticalSavedPaymentMethodsViewController(configuration: configuration,
                                                           selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
                                                           paymentMethods: savedPaymentMethods)
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
    func didComplete(with selectedPaymentMethod: STPPaymentMethod?, latestPaymentMethods: [STPPaymentMethod]) {
        // TODO
        print("Selected payment method with id: \(String(describing: selectedPaymentMethod?.stripeId))")
        // Update our list of saved payment methods to be the latest from the manage screen incase of updates/removals
        savedPaymentMethods = latestPaymentMethods
    }
}
