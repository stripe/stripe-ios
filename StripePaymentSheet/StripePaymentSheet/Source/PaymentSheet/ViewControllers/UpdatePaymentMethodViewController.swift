//
//  UpdatePaymentMethodViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/27/23.
//
import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

@MainActor
protocol UpdatePaymentMethodViewControllerDelegate: AnyObject {
    func didRemove(viewController: UpdatePaymentMethodViewController, paymentMethod: STPPaymentMethod)
    func didUpdate(viewController: UpdatePaymentMethodViewController,
                   paymentMethod: STPPaymentMethod,
                   updateParams: STPPaymentMethodUpdateParams) async throws
    func shouldCloseSheet(_: UpdatePaymentMethodViewController)
}

/// For internal SDK use only
@objc(STP_Internal_UpdatePaymentMethodViewController)
final class UpdatePaymentMethodViewController: UIViewController {
    private let removeSavedPaymentMethodMessage: String?
    private let isTestMode: Bool
    private let viewModel: UpdatePaymentMethodViewModel

    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }

    weak var delegate: UpdatePaymentMethodViewControllerDelegate?

    // MARK: Navigation bar
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: isTestMode,
                                        appearance: viewModel.appearance)
        navBar.delegate = self
        navBar.setStyle(navigationBarStyle())
        return navBar
    }()

    // MARK: Views
    lazy var formStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [headerLabel, paymentMethodForm, updateButton, removeButton, errorLabel])
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(16, after: headerLabel) // custom spacing from figma
        if let footnoteLabel = footnoteLabel {
            stackView.insertArrangedSubview(footnoteLabel, at: 2)
            stackView.setCustomSpacing(8, after: paymentMethodForm) // custom spacing from figma
            stackView.setCustomSpacing(32, after: footnoteLabel) // custom spacing from figma
        }
        else {
            stackView.setCustomSpacing(32, after: paymentMethodForm) // custom spacing from figma
        }
        stackView.setCustomSpacing(16, after: updateButton) // custom spacing from figma
        return stackView
    }()

    private lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: viewModel.appearance)
        label.text = viewModel.header
        return label
    }()

    private lazy var updateButton: ConfirmButton = {
        let button = ConfirmButton(state: .disabled, callToAction: .custom(title: .Localized.save), appearance: viewModel.appearance, didTap: {  [weak self] in
            switch self?.viewModel.paymentMethod.type {
            case .card:
                Task {
                    await self?.updateCard()
                }
            default:
                fatalError("Updating payment method has not been implemented for \(self?.viewModel.paymentMethod.type ?? .unknown)")
            }
        })
        button.isHidden = !viewModel.canEdit
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        let font = viewModel.appearance.primaryButton.font ?? viewModel.appearance.scaledFont(for: viewModel.appearance.font.base.medium, style: .callout, maximumPointSize: 25)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.bordered()
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            configuration.baseBackgroundColor = .clear
            configuration.background.cornerRadius = viewModel.appearance.cornerRadius
            configuration.background.strokeWidth = viewModel.appearance.selectedBorderWidth ?? viewModel.appearance.borderWidth * 1.5
            configuration.background.strokeColor = viewModel.appearance.colors.danger
            configuration.titleAlignment = .center
            configuration.attributedTitle = AttributedString(.Localized.remove, attributes: AttributeContainer([.font: font, .foregroundColor: viewModel.appearance.colors.danger]))
            button.configuration = configuration
        } else {
            button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
            button.setTitleColor(viewModel.appearance.colors.danger, for: .normal)
            button.setTitleColor(viewModel.appearance.colors.danger.disabledColor, for: .highlighted)
            button.layer.borderColor = viewModel.appearance.colors.danger.cgColor
            button.layer.borderWidth = viewModel.appearance.selectedBorderWidth ?? viewModel.appearance.borderWidth * 1.5
            button.layer.cornerRadius = viewModel.appearance.cornerRadius
            button.setTitle(.Localized.remove, for: .normal)
            button.titleLabel?.textAlignment = .center
            button.titleLabel?.font = font
            button.titleLabel?.adjustsFontForContentSizeCategory = true
        }
        button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        button.addTarget(self, action: #selector(removePaymentMethod), for: .touchUpInside)
        button.isHidden = !viewModel.canRemove
        return button
    }()

    @objc private func buttonTouchDown(_ button: UIButton) {
        if #available(iOS 15.0, *)  {
            button.configuration?.attributedTitle?.foregroundColor = viewModel.appearance.colors.danger.disabledColor
            button.configuration?.background.strokeColor = viewModel.appearance.colors.danger.disabledColor
        }
        else {
            button.setTitleColor(viewModel.appearance.colors.danger.disabledColor, for: .normal)
            button.layer.borderColor = viewModel.appearance.colors.danger.disabledColor.cgColor
        }
    }

    @objc private func buttonTouchUp(_ button: UIButton) {
        if #available(iOS 15.0, *)  {
            button.configuration?.attributedTitle?.foregroundColor = viewModel.appearance.colors.danger
            button.configuration?.background.strokeColor = viewModel.appearance.colors.danger
        }
        else {
            button.setTitleColor(viewModel.appearance.colors.danger, for: .normal)
            button.layer.borderColor = viewModel.appearance.colors.danger.cgColor
        }
    }

    private lazy var paymentMethodForm: UIView = {
        let form = SavedPaymentMethodFormFactory(viewModel: viewModel)
        form.delegate = self
        return form.makePaymentMethodForm()
    }()

    private lazy var footnoteLabel: UITextView? = {
        if viewModel.errorState {
            return nil
        }
        let label = ElementsUI.makeSmallFootnote(theme: viewModel.appearance.asElementsTheme)
        label.text = viewModel.footnote
        return label
    }()

    private lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: viewModel.appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: Overrides
    init(removeSavedPaymentMethodMessage: String?,
         isTestMode: Bool,
         viewModel: UpdatePaymentMethodViewModel) {
        self.removeSavedPaymentMethodMessage = removeSavedPaymentMethodMessage
        self.isTestMode = isTestMode
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // disable swipe to dismiss
        isModalInPresentation = true
        self.view.backgroundColor = viewModel.appearance.colors.background
        view.addAndPinSubview(formStackView, insets: PaymentSheetUI.defaultSheetMargins)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .openCardBrandEditScreen))
    }

    // MARK: Private helpers
    private func dismiss() {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
        delegate?.shouldCloseSheet(_: self)
    }

    private func navigationBarStyle() -> SheetNavigationBar.Style {
        if let bottomSheet = self.bottomSheetController,
           bottomSheet.contentStack.count > 1 {
            return .back(showAdditionalButton: false)
        } else {
            return .close(showAdditionalButton: false)
        }
    }

    @objc private func removePaymentMethod() {
        let alertController = UIAlertController.makeRemoveAlertController(paymentMethod: viewModel.paymentMethod,
                                                                          removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage) { [weak self] in
            guard let self = self else { return }
            self.delegate?.didRemove(viewController: self, paymentMethod: self.viewModel.paymentMethod)
        }

        present(alertController, animated: true, completion: nil)
    }

    private func updateCard() async {
        guard let selectedBrand = viewModel.selectedCardBrand, let delegate = delegate else { return }

        view.isUserInteractionEnabled = false
        updateButton.update(state: .spinnerWithInteractionDisabled)

        // Create the update card params
        let cardParams = STPPaymentMethodCardParams()
        cardParams.networks = .init(preferred: STPCardBrandUtilities.apiValue(from: selectedBrand))
        let updateParams = STPPaymentMethodUpdateParams(card: cardParams, billingDetails: nil)

        // Make the API request to update the payment method
        do {
            try await delegate.didUpdate(viewController: self, paymentMethod: viewModel.paymentMethod, updateParams: updateParams)
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .updateCardBrand),
                                                                 params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedBrand)])
        } catch {
            updateButton.update(state: .enabled)
            latestError = error
            STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .updateCardBrandFailed),
                                                                 error: error,
                                                                 params: ["selected_card_brand": STPCardBrandUtilities.apiValue(from: selectedBrand)])
        }
        view.isUserInteractionEnabled = true
    }

}

// MARK: BottomSheetContentViewController
extension UpdatePaymentMethodViewController: BottomSheetContentViewController {

    func didTapOrSwipeToDismiss() {
        guard view.isUserInteractionEnabled else {
            return
        }

        dismiss()
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: SheetNavigationBarDelegate
extension UpdatePaymentMethodViewController: SheetNavigationBarDelegate {

    func sheetNavigationBarDidClose(_: SheetNavigationBar) {
        dismiss()
    }

    func sheetNavigationBarDidBack(_: SheetNavigationBar) {
        guard let bottomVc = parent as? BottomSheetViewController else { return }
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: viewModel.hostedSurface.analyticEvent(for: .closeEditScreen))
        _ = bottomVc.popContentViewController()
    }

}

// MARK: SavedPaymentMethodFormFactoryDelegate
extension UpdatePaymentMethodViewController: SavedPaymentMethodFormFactoryDelegate {
    func didUpdate(_: Element, shouldEnableSaveButton: Bool) {
        latestError = nil // clear error on new input
        switch viewModel.paymentMethod.type {
        case .card:
            updateButton.update(state: shouldEnableSaveButton ? .enabled : .disabled)
        default:
            break
        }
    }
}
