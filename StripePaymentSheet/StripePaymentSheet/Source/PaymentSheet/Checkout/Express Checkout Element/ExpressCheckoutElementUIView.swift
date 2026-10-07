//
//  ExpressCheckoutElementUIView.swift
//  StripePaymentSheet
//
//  Created by Joyce Qin on 7/22/26.
//

import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A UIKit view that displays wallet payment buttons (Apple Pay, Link).
@_spi(STP)
@_spi(ReactNativeSDK)
@MainActor
public final class ExpressCheckoutElementUIView: UIView {

    private enum Constants {
        static let buttonHeight: CGFloat = 44
        static let buttonSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 6
    }

    // MARK: - Private Properties

    private let configuration: ExpressCheckoutElement.Configuration
    private let apiClient: STPAPIClient
    private let analyticsClient: STPAnalyticsClientProtocol
    private let stackView = UIStackView()
    private var hasReportedInit = false
    private var linkBrand: LinkBrand
    private var session: CheckoutController.Session
    private weak var delegate: ExpressCheckoutElementDelegate?

    // MARK: - Init

    init(
        session: CheckoutController.Session,
        configuration: ExpressCheckoutElement.Configuration,
        delegate: ExpressCheckoutElementDelegate,
        apiClient: STPAPIClient = .shared,
        analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    ) {
        self.configuration = configuration
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
        self.delegate = delegate
        self.linkBrand = session.elementsSession.linkBrand ?? .link
        self.session = session
        super.init(frame: .zero)

        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Constants.buttonSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal Methods

    func update(
        with session: CheckoutController.Session,
        buttons: [ExpressCheckoutElement.PaymentMethod]
    ) {
        self.session = session
        linkBrand = session.elementsSession.linkBrand ?? .link
        layoutButtons(buttons)
        invalidateIntrinsicContentSize()
    }

    // MARK: - Public Methods

    public override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        )
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil, !hasReportedInit else { return }
        hasReportedInit = true
        analyticsClient.log(
            analytic: PaymentSheetAnalytic(
                event: .expressCheckoutElementInit,
                additionalParams: [
                    "ordered_lpms": session.availableExpressCheckoutPaymentMethods.joined(separator: ","),
                    "ece_config": [
                        "link_visibility": configuration.linkConfiguration.display.rawValue,
                        "apple_pay_visibility": configuration.applePayConfiguration?.display.rawValue ?? "never",
                    ],
                ]
            ),
            apiClient: apiClient
        )
    }

    // MARK: - Private Methods

    /// Arranges `buttons` into no more than `appearance.buttonLayout.maxRows` rows of no more than `appearance.buttonLayout.maxColumns` columns.
    private func layoutButtons(_ buttons: [ExpressCheckoutElement.PaymentMethod]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let buttonRows = Self.buttonRows(for: buttons, layout: configuration.appearance.buttonLayout)
            .map { row in row.map { makeButton(for: $0) } }
        guard let firstRow = buttonRows.first, let referenceButton = firstRow.first else { return }
        let columnCount = firstRow.count

        for buttons in buttonRows {
            let rowStackView = makeRowStackView(buttons)
            stackView.addArrangedSubview(rowStackView)

            // Complete rows establish the column width. Incomplete rows retain that
            // button width and are centered by the outer stack view.
            if buttons.count == columnCount {
                rowStackView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            }
        }

        // Set button widths matching the referenceButton width
        buttonRows.joined().dropFirst().forEach {
            $0.widthAnchor.constraint(equalTo: referenceButton.widthAnchor).isActive = true
        }
    }

    private func makeRowStackView(_ buttons: [UIView]) -> UIStackView {
        let rowStackView = UIStackView(arrangedSubviews: buttons)
        rowStackView.axis = .horizontal
        rowStackView.spacing = Constants.buttonSpacing
        return rowStackView
    }

    static func buttonRows(
        for buttons: [ExpressCheckoutElement.PaymentMethod],
        layout: ExpressCheckoutElement.Appearance.ButtonLayout
    ) -> [[ExpressCheckoutElement.PaymentMethod]] {
        let visibleButtonCount = calculateVisibleButtonCount(
            buttonCount: buttons.count,
            maxColumns: layout.maxColumns,
            maxRows: layout.maxRows
        )
        let visibleButtons = Array(buttons.prefix(visibleButtonCount))
        let columnCount = calculateColumnCount(
            buttonCount: visibleButtonCount,
            maxRows: layout.maxRows
        )

        var rows: [[ExpressCheckoutElement.PaymentMethod]] = []
        var rowStartIndex = 0
        while rowStartIndex < visibleButtons.count {
            // The final row may contain fewer buttons than the other rows.
            let rowEndIndex = min(rowStartIndex + columnCount, visibleButtons.count)
            let row = Array(visibleButtons[rowStartIndex..<rowEndIndex])
            rows.append(row)
            rowStartIndex = rowEndIndex
        }
        return rows
    }

    static func calculateVisibleButtonCount(
        buttonCount: Int,
        maxColumns: Int?,
        maxRows: Int?
    ) -> Int {
        // A single limit affects how the buttons are arranged, but it cannot
        // limit the grid's total capacity without the other dimension.
        guard let maxColumns, let maxRows else {
            return buttonCount
        }
        return min(maxRows * maxColumns, buttonCount)
    }

    static func calculateColumnCount(buttonCount: Int, maxRows: Int?) -> Int {
        guard buttonCount > 0 else {
            return 1
        }
        // Prefer one column unless that would exceed the configured row limit.
        guard let maxRows, maxRows < buttonCount else {
            return 1
        }
        // Integer division rounds down. Adding `maxRows - 1` rounds the result
        // up so every visible button fits within `maxRows` rows.
        return (buttonCount + maxRows - 1) / maxRows
    }

    private func makeButton(for paymentMethod: ExpressCheckoutElement.PaymentMethod) -> UIView {
        switch paymentMethod {
        case .applePay:
            return makeApplePayButton()
        case .link:
            return makeLinkButton()
        }
    }

    private func makeApplePayButton() -> UIView {
        let buttonType = configuration.applePayConfiguration?.buttonType ?? .plain
        let button = PKPaymentButton(paymentButtonType: buttonType, paymentButtonStyle: applePayButtonStyle)
        // `cornerConfiguration` doesn't work on PKPaymentButton, so set the radius directly.
        button.cornerRadius = LiquidGlassDetector.isEnabledInMerchantApp
            ? Constants.buttonHeight / 2
            : Constants.cornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(handleApplePayTapped), for: .touchUpInside)
        return button
    }

    private func makeLinkButton() -> UIView {
        let button = PayWithLinkButton(brand: linkBrand)
        if LiquidGlassDetector.isEnabledInMerchantApp {
            button.ios26_applyCapsuleCornerConfiguration()
        } else {
            button.cornerRadius = Constants.cornerRadius
        }
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: Constants.buttonHeight).isActive = true
        button.addTarget(self, action: #selector(handleLinkTapped), for: .touchUpInside)
        return button
    }

    /// `PayWithLinkButton` always uses Link's brand color, so `buttonTheme` only affects the Apple Pay button.
    private var applePayButtonStyle: PKPaymentButtonStyle {
        switch configuration.appearance.buttonTheme {
        case .light:
            return .white
        case .dark:
            return .black
        case .automatic:
            return .automatic
        }
    }

    @objc private func handleApplePayTapped() {
        confirm(.applePay)
    }

    @objc private func handleLinkTapped() {
        confirm(.link)
    }

    private func confirm(_ paymentMethod: ExpressCheckoutElement.PaymentMethod) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let result = await self.delegate?.expressCheckoutElementShouldConfirm(
                paymentMethod,
                presentationWindow: window
            ) else { return }
            self.configuration.confirmHandler(result)
        }
    }
}
