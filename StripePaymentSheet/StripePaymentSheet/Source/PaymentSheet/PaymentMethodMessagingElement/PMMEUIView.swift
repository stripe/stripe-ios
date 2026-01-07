//
//  PMMEUIView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class PMMEUIView: UIView {

    private let infoUrl: URL
    private let appearance: PaymentMethodMessagingElement.Appearance
    private let analyticsHelper: PMMEAnalyticsHelper

    // Callback to notify SwiftUI of height changes. Unneeded if used in a UIKit context.
    private let didUpdateHeight: ((CGFloat) -> Void)?
    private var previousHeight: CGFloat?

    // What UI context the view is shown from, for analytics purposes
    private let integrationType: PMMEAnalyticsHelper.IntegrationType

    // With the default font, padding between the content and legal disclosure is 4
    private var verticalPadding: CGFloat {
        appearance.fontScaled(4)
    }

    init(
        viewData: PaymentMethodMessagingElement.ViewData,
        integrationType: PMMEAnalyticsHelper.IntegrationType,
        didUpdateHeight: ((CGFloat) -> Void)? = nil
    ) {
        self.infoUrl = viewData.infoUrl
        self.appearance = viewData.appearance
        self.analyticsHelper = viewData.analyticsHelper
        self.integrationType = integrationType
        self.didUpdateHeight = didUpdateHeight
        super.init(frame: .zero)

        // on tap behavior for opening info url
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))

        // set interface style
        switch appearance.style {
        case .alwaysDark:
            overrideUserInterfaceStyle = .dark
        case .alwaysLight, .flat:
            overrideUserInterfaceStyle = .light
        case .automatic:
            break
        }

        isAccessibilityElement = true
        accessibilityHint = STPLocalizedString(
            "Open to see more information.",
            "Accessibility hint to tell the user that they can open a form sheet with more information."
        )

        // create wrapper view that will hold the main PMME view and the legal disclosure if needed
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = verticalPadding
        addAndPinSubview(stackView)

        // choose which style to initialize
        switch viewData.mode {
        case .singlePartner(let logo):
            let view = PMMESinglePartnerView(logoSet: logo, promotion: viewData.promotion, appearance: appearance)
            stackView.addArrangedSubview(view)
            accessibilityLabel = view.customAccessibilityLabel
        case .multiPartner(let logos):
            let view = PMMEMultiPartnerView(logoSets: logos, promotion: viewData.promotion, appearance: appearance)
            stackView.addArrangedSubview(view)
            accessibilityLabel = view.customAccessibilityLabel
        }

        // add legal disclosure if needed
        if let legalText = viewData.legalDisclosure {
            // TODO(gbirch): add appearance customization for legal text
            let legalLabel = UILabel()
            legalLabel.text = legalText
            legalLabel.font = UIFont.preferredFont(forTextStyle: .caption1, weight: .regular, maximumPointSize: 20)
            legalLabel.textColor = .secondaryLabel
            stackView.addArrangedSubview(legalLabel)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Calculate our natural height
        let desiredHeight = systemLayoutSizeFitting(CGSize(width: frame.width, height: UIView.layoutFittingCompressedSize.height)).height

        // Notify if changed
        if desiredHeight != previousHeight {
            didUpdateHeight?(desiredHeight)
            self.previousHeight = desiredHeight
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        analyticsHelper.logDisplayed(integrationType: integrationType)
    }

    @objc private func didTap() {
        analyticsHelper.logTapped()

        let infoController = PMMEInfoModal(infoUrl: infoUrl, style: appearance.style)
        infoController.modalPresentationStyle = .formSheet
        window?.findTopMostPresentedViewController()?.present(infoController, animated: true)
    }
}
