//
//  LinkFullConsentViewController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 8/23/25.
//

@_spi(STP) import StripeUICore
import UIKit

protocol LinkFullConsentViewControllerDelegate: AnyObject {
    @MainActor func fullConsentViewController(
        _ controller: LinkFullConsentViewController,
        didFinishWithResult result: LinkController.AuthorizationResult
    )
}

/// For internal SDK use only
@objc(STP_Internal_LinkFullConsentViewController)
final class LinkFullConsentViewController: UIViewController, BottomSheetContentViewController {

    weak var delegate: LinkFullConsentViewControllerDelegate?

    private let viewModel: LinkConsentViewModel.FullConsentViewModel

    private lazy var headerView: LinkFullConsentHeaderView = {
        return LinkFullConsentHeaderView(
            merchantLogoURL: viewModel.merchantLogoURL,
            title: viewModel.title
        )
    }()

    private lazy var emailView: LinkFullConsentEmailView = {
        return LinkFullConsentEmailView(email: viewModel.email)
    }()

    private lazy var scopesHeaderLabel: UILabel? = {
        guard let scopesSection = viewModel.scopesSectionIfNotEmpty else {
            return nil
        }
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = scopesSection.header
        label.font = LinkUI.font(forTextStyle: .detail)
        label.textColor = .linkTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var scopesView: LinkFullConsentScopesView? = {
        guard let scopesSection = viewModel.scopesSectionIfNotEmpty else {
            return nil
        }
        return LinkFullConsentScopesView(scopes: scopesSection.scopes)
    }()

    private lazy var footerView: LinkFullConsentFooterView = {
        let footer = LinkFullConsentFooterView(viewModel: viewModel)
        footer.delegate = self
        return footer
    }()

    private lazy var containerView: UIStackView = {
        var arrangedSubviews: [UIView] = [
            headerView,
            emailView,
        ]

        let scopesViews = [scopesHeaderLabel, scopesView].compactMap(\.self)
        arrangedSubviews.append(contentsOf: scopesViews)

        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = .vertical
        stackView.spacing = LinkUI.largeContentSpacing
        stackView.alignment = .center
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = LinkUI.contentMargins
        stackView.translatesAutoresizingMaskIntoConstraints = false

        if let scopesHeaderLabel {
            stackView.setCustomSpacing(LinkUI.contentSpacing, after: scopesHeaderLabel)
        }

        return stackView
    }()

    private lazy var mainContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            containerView,
            footerView,
        ])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(consentViewModel: LinkConsentViewModel.FullConsentViewModel) {
        self.viewModel = consentViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .linkSurfacePrimary
        setupUI()
    }

    private func setupUI() {
        view.addAndPinSubview(mainContainerView)

        if let scopesHeaderLabel {
            NSLayoutConstraint.activate([
                scopesHeaderLabel.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
                scopesHeaderLabel.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            ])
        }
        if let scopesView {
            NSLayoutConstraint.activate([
                scopesView.leadingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.leadingAnchor),
                scopesView.trailingAnchor.constraint(equalTo: containerView.layoutMarginsGuide.trailingAnchor),
            ])
        }
    }
}

// MARK: - BottomSheetContentViewController

extension LinkFullConsentViewController {
    var navigationBar: SheetNavigationBar {
        let navBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: LinkUI.appearance,
            shouldLogPaymentSheetAnalyticsOnDismissal: false
        )
        navBar.setStyle(.close(showAdditionalButton: false))
        navBar.delegate = self
        return navBar
    }

    var requiresFullScreen: Bool { false }

    func didTapOrSwipeToDismiss() {
        delegate?.fullConsentViewController(self, didFinishWithResult: .canceled)
    }
}

// MARK: - LinkFullConsentFooterViewDelegate

extension LinkFullConsentViewController: LinkFullConsentFooterViewDelegate {
    func footerViewDidTapConsent(_ footerView: LinkFullConsentFooterView) {
        delegate?.fullConsentViewController(self, didFinishWithResult: .consented)
    }

    func footerViewDidTapReject(_ footerView: LinkFullConsentFooterView) {
        delegate?.fullConsentViewController(self, didFinishWithResult: .denied)
    }
}

// MARK: - SheetNavigationBarDelegate

extension LinkFullConsentViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.fullConsentViewController(self, didFinishWithResult: .canceled)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.fullConsentViewController(self, didFinishWithResult: .canceled)
    }
}
