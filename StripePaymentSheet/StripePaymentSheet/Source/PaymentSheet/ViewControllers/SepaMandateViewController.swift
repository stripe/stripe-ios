//
//  SepaMandateViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/6/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

class SepaMandateViewController: UIViewController, BottomSheetContentViewController {
    let requiresFullScreen: Bool = false

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode, appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()
    private lazy var sepaMandateView: SimpleMandateTextView = {
        let mandateText = String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName)
        let view = SimpleMandateTextView(mandateText: mandateText, theme: configuration.appearance.asElementsTheme)
        return view
    }()

    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: .customWithLock(title: String.Localized.continue),
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.completion(true)
            }
        )
        return button
    }()
    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = STPPaymentMethodType.SEPADebit.displayName
        return label
    }()

    let configuration: PaymentSheet.Configuration
    let completion: (Bool) -> Void

    /// - Parameter completion: Called with `true` after the customer accepts the mandate by tapping the "continue" button, or called with `false` after the customer dismisses the view (either by tapping out or swiping down). Does not dismiss the view controller.
    required init(configuration: PaymentSheet.Configuration, completion: @escaping (Bool) -> Void) {
        self.configuration = configuration
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        let stackView = UIStackView(arrangedSubviews: [headerLabel, sepaMandateView, confirmButton])
        stackView.axis = .vertical
        stackView.spacing = PaymentSheetUI.defaultPadding

        view.addAndPinSubviewToSafeArea(stackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    func didTapOrSwipeToDismiss() {
        self.completion(false)
    }
}

extension SepaMandateViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        self.completion(false)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        self.completion(false)
    }
}
