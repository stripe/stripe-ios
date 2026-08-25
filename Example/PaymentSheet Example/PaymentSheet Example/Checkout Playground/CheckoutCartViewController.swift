//
//  CheckoutCartViewController.swift
//  PaymentSheet Example
//
//  Created by George Birch on 8/10/26.
//

import Combine
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI
import UIKit

struct CheckoutCartUIKitView: UIViewControllerRepresentable {

    @Environment(\.dismiss) private var dismiss

    let clientSecret: String
    let shippingAddressCollection: Bool
    let defaultShippingAddress: CheckoutPlayground.DefaultShippingAddress?
    let adaptivePricing: Bool
    let integrationType: CheckoutPlayground.IntegrationType
    let showExpressCheckoutElement: Bool
    let applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display
    let linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display
    let eceShippingAddressRequired: Bool
    var eceBillingDetailsCollectionConfiguration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration
    let currencySelectorAppearance: CurrencySelectorElement.Appearance
    let delayPaymentPagesRequests: Bool

    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = CheckoutCartViewController(
            clientSecret: clientSecret,
            shippingAddressCollection: shippingAddressCollection,
            defaultShippingAddress: defaultShippingAddress,
            adaptivePricing: adaptivePricing,
            integrationType: integrationType,
            showExpressCheckoutElement: showExpressCheckoutElement,
            applePayDisplay: applePayDisplay,
            linkDisplay: linkDisplay,
            eceShippingAddressRequired: eceShippingAddressRequired,
            eceBillingDetailsCollectionConfiguration: eceBillingDetailsCollectionConfiguration,
            currencySelectorAppearance: currencySelectorAppearance,
            delayPaymentPagesRequests: delayPaymentPagesRequests,
            closeAction: { dismiss() }
        )
        return UINavigationController(rootViewController: viewController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

@MainActor
final class CheckoutCartViewController: UIViewController {

    private let clientSecret: String
    private let shippingAddressCollection: Bool
    private let defaultShippingAddress: CheckoutPlayground.DefaultShippingAddress?
    private let adaptivePricing: Bool
    private let integrationType: CheckoutPlayground.IntegrationType
    private let showExpressCheckoutElement: Bool
    private let eceShippingAddressRequired: Bool
    private let applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display
    private let linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display
    private let eceBillingDetailsCollectionConfiguration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration
    private let currencySelectorAppearance: CurrencySelectorElement.Appearance
    private let delayPaymentPagesRequests: Bool
    private let closeAction: () -> Void
    private let diagnostics = CheckoutSessionDiagnostics()

    private var checkout: CheckoutController?
    private var cancellables = Set<AnyCancellable>()
    private var isUpdatingShippingAddress = false

    private let rootStackView = UIStackView()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let paymentBarStackView = UIStackView()

    private let statusContainerView = UIView()
    private let statusStackView = UIStackView()
    private let statusActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    private let loadingOverlayView = UIView()
    private let loadingActivityIndicator = UIActivityIndicatorView(style: .medium)
    private weak var checkoutButton: UIButton?
    private weak var checkoutButtonContentView: UIStackView?
    private weak var checkoutButtonActivityIndicator: UIActivityIndicatorView?
    private var errorMessage: String?

    init(
        clientSecret: String,
        shippingAddressCollection: Bool,
        defaultShippingAddress: CheckoutPlayground.DefaultShippingAddress?,
        adaptivePricing: Bool,
        integrationType: CheckoutPlayground.IntegrationType,
        showExpressCheckoutElement: Bool,
        applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display,
        linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display,
        eceShippingAddressRequired: Bool,
        eceBillingDetailsCollectionConfiguration: ExpressCheckoutElement.BillingDetailsCollectionConfiguration,
        currencySelectorAppearance: CurrencySelectorElement.Appearance,
        delayPaymentPagesRequests: Bool,
        closeAction: @escaping () -> Void
    ) {
        self.clientSecret = clientSecret
        self.shippingAddressCollection = shippingAddressCollection
        self.defaultShippingAddress = defaultShippingAddress
        self.adaptivePricing = adaptivePricing
        self.integrationType = integrationType
        self.showExpressCheckoutElement = showExpressCheckoutElement
        self.eceShippingAddressRequired = eceShippingAddressRequired
        self.applePayDisplay = applePayDisplay
        self.linkDisplay = linkDisplay
        self.eceBillingDetailsCollectionConfiguration = eceBillingDetailsCollectionConfiguration
        self.currencySelectorAppearance = currencySelectorAppearance
        self.delayPaymentPagesRequests = delayPaymentPagesRequests
        self.closeAction = closeAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Your Cart"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )

        configureViewHierarchy()
        showLoadingStatus()
        Task { await loadCheckout() }
    }

    private func configureViewHierarchy() {
        rootStackView.axis = .vertical
        rootStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStackView)

        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStackView)
        rootStackView.addArrangedSubview(scrollView)

        paymentBarStackView.axis = .vertical
        paymentBarStackView.spacing = 12
        paymentBarStackView.isLayoutMarginsRelativeArrangement = true
        paymentBarStackView.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        paymentBarStackView.backgroundColor = .systemBackground
        paymentBarStackView.layer.shadowColor = UIColor.black.cgColor
        paymentBarStackView.layer.shadowOpacity = 0.1
        paymentBarStackView.layer.shadowRadius = 10
        paymentBarStackView.layer.shadowOffset = CGSize(width: 0, height: -5)
        paymentBarStackView.isHidden = true
        rootStackView.addArrangedSubview(paymentBarStackView)

        statusStackView.axis = .vertical
        statusStackView.alignment = .center
        statusStackView.spacing = 12
        statusStackView.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        retryButton.setTitle("Retry", for: .normal)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        statusStackView.addArrangedSubview(statusActivityIndicator)
        statusStackView.addArrangedSubview(statusLabel)
        statusStackView.addArrangedSubview(retryButton)
        statusContainerView.translatesAutoresizingMaskIntoConstraints = false
        statusContainerView.addSubview(statusStackView)
        view.addSubview(statusContainerView)

        loadingOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        loadingOverlayView.translatesAutoresizingMaskIntoConstraints = false
        loadingActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlayView.addSubview(loadingActivityIndicator)
        loadingOverlayView.isHidden = true
        view.addSubview(loadingOverlayView)

        NSLayoutConstraint.activate([
            rootStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            rootStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),

            statusContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            statusContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            statusStackView.centerXAnchor.constraint(equalTo: statusContainerView.centerXAnchor),
            statusStackView.centerYAnchor.constraint(equalTo: statusContainerView.centerYAnchor),
            statusStackView.leadingAnchor.constraint(greaterThanOrEqualTo: statusContainerView.leadingAnchor, constant: 24),
            statusStackView.trailingAnchor.constraint(lessThanOrEqualTo: statusContainerView.trailingAnchor, constant: -24),

            loadingOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingActivityIndicator.centerXAnchor.constraint(equalTo: loadingOverlayView.centerXAnchor),
            loadingActivityIndicator.centerYAnchor.constraint(equalTo: loadingOverlayView.centerYAnchor),
        ])
    }

    private func loadCheckout() async {
        showLoadingStatus()
        errorMessage = nil
        cancellables.removeAll()

        do {
            var configuration = CheckoutController.Configuration(
                clientSecret: clientSecret,
                returnURL: "payments-example://stripe-redirect"
            )
            configuration.adaptivePricing.allowed = adaptivePricing
            configuration.defaults.shippingDetails = defaultShippingAddress?.checkoutShippingDetails
            configuration.applePayConfiguration = CheckoutController.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example"
            )
            var expressCheckoutElementConfig = ExpressCheckoutElement.Configuration()
            expressCheckoutElementConfig.billingDetailsCollectionConfiguration = eceBillingDetailsCollectionConfiguration
            configuration.expressCheckoutElement = expressCheckoutElementConfig
            configuration.currencySelectorElement.appearance = currencySelectorAppearance
            configuration.expressCheckoutElement.shippingAddressRequired = eceShippingAddressRequired
            configuration.expressCheckoutElement.applePayConfiguration = ExpressCheckoutElement.ApplePayConfiguration(
                merchantId: "merchant.com.stripe.paymentsheet.example",
                display: applePayDisplay
            )
            configuration.expressCheckoutElement.linkConfiguration = ExpressCheckoutElement.LinkConfiguration(display: linkDisplay)
            configuration.apiClient = diagnostics.makeAPIClient(
                paymentPagesRequestDelay: delayPaymentPagesRequests ? 1 : 0
            )

            let checkout = try await CheckoutController(configuration: configuration)
            self.checkout = checkout
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "ladybug"),
                style: .plain,
                target: self,
                action: #selector(checkoutDetailsButtonTapped)
            )
            navigationItem.rightBarButtonItem?.accessibilityLabel = "Session diagnostics"
            observeCheckout(checkout)
            statusContainerView.isHidden = true
            scrollView.isHidden = false
            renderCheckout()
        } catch {
            checkout = nil
            navigationItem.rightBarButtonItem = nil
            errorMessage = error.localizedDescription
            showFailureStatus()
        }
    }

    private func observeCheckout(_ checkout: CheckoutController) {
        checkout.$session
            .dropFirst()
            .sink { [weak self] _ in
                self?.renderCheckout()
            }
            .store(in: &cancellables)

        checkout.$isUpdating
            .sink { [weak self] _ in
                self?.updateLoadingOverlay()
            }
            .store(in: &cancellables)
    }

    private func renderCheckout() {
        guard let checkout else { return }

        removeAllArrangedSubviews(from: contentStackView)

        if let errorMessage {
            contentStackView.addArrangedSubview(makeErrorBanner(message: errorMessage))
        }

        if let currencySelectorElement = checkout.getCurrencySelectorElement() {
            contentStackView.addArrangedSubview(currencySelectorElement.uiView)
        }

        contentStackView.addArrangedSubview(makeLineItemsSection(checkout: checkout))

        if shippingAddressCollection || checkout.session.shippingAddress != nil {
            contentStackView.addArrangedSubview(makeShippingAddressSection(checkout: checkout))
        }

        contentStackView.addArrangedSubview(makeOrderSummarySection(session: checkout.session))

        renderPaymentBar(checkout: checkout)
        updateLoadingOverlay()
    }

    private func renderPaymentBar(checkout: CheckoutController) {
        removeAllArrangedSubviews(from: paymentBarStackView)

        if showExpressCheckoutElement, let expressCheckoutElement = checkout.getExpressCheckoutElement() {
            paymentBarStackView.addArrangedSubview(expressCheckoutElement.uiView)
        }

        switch integrationType {
        case .flowController, .embedded:
            paymentBarStackView.addArrangedSubview(makePaymentMethodRow(checkout: checkout))
            paymentBarStackView.addArrangedSubview(makeCheckoutButton(checkout: checkout))
        case .eceOnly:
            break
        }

        paymentBarStackView.isHidden = paymentBarStackView.arrangedSubviews.isEmpty
    }

    private func makeLineItemsSection(checkout: CheckoutController) -> UIView {
        let itemsStackView = UIStackView()
        itemsStackView.axis = .vertical

        let items = checkout.session.orderSummaryItems.flatMap { orderSummaryItem in
            switch orderSummaryItem {
            case .oneTimePrice(let oneTimePrice):
                return oneTimePrice.items
            }
        }
        if items.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No items"
            emptyLabel.textColor = .secondaryLabel
            itemsStackView.addArrangedSubview(makePaddedView(containing: emptyLabel))
        } else {
            for (index, item) in items.enumerated() {
                itemsStackView.addArrangedSubview(
                    makeLineItemRow(item: item)
                )
                if index < items.count - 1 {
                    itemsStackView.addArrangedSubview(makeSeparator())
                }
            }
        }

        return makeSection(title: "Items", content: makeCard(containing: itemsStackView))
    }

    private func makeLineItemRow(item: CheckoutController.Session.OrderSummaryItem.OneTimePrice.Item) -> UIView {
        let placeholderView = UIView()
        placeholderView.backgroundColor = .secondarySystemBackground
        placeholderView.layer.cornerRadius = 12
        placeholderView.translatesAutoresizingMaskIntoConstraints = false

        let imageView = UIImageView(image: UIImage(systemName: "photo"))
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        placeholderView.addSubview(imageView)

        let nameLabel = UILabel()
        nameLabel.text = item.displayName
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        nameLabel.numberOfLines = 0

        let unitAmountLabel = UILabel()
        unitAmountLabel.text = "\((item.unitAmountDecimal ?? item.unitAmount).amount) × \(item.quantity)"
        unitAmountLabel.font = .preferredFont(forTextStyle: .subheadline)
        unitAmountLabel.textColor = .secondaryLabel

        let detailsStackView = UIStackView(arrangedSubviews: [nameLabel, unitAmountLabel])
        detailsStackView.axis = .vertical
        detailsStackView.spacing = 6

        let rowStackView = UIStackView(arrangedSubviews: [placeholderView, detailsStackView])
        rowStackView.alignment = .top
        rowStackView.spacing = 16

        NSLayoutConstraint.activate([
            placeholderView.widthAnchor.constraint(equalToConstant: 80),
            placeholderView.heightAnchor.constraint(equalToConstant: 80),
            imageView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 24),
            imageView.heightAnchor.constraint(equalToConstant: 24),
        ])

        return makePaddedView(containing: rowStackView)
    }

    private func makeShippingAddressSection(checkout: CheckoutController) -> UIView {
        let cardContent: UIView
        if let shippingAddress = checkout.session.shippingAddress {
            let iconView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
            iconView.tintColor = .systemBlue
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false

            let addressStackView = UIStackView()
            addressStackView.axis = .vertical
            addressStackView.spacing = 4

            if let name = shippingAddress.name, !name.isEmpty {
                let nameLabel = UILabel()
                nameLabel.text = name
                nameLabel.font = .preferredFont(forTextStyle: .headline)
                addressStackView.addArrangedSubview(nameLabel)
            }

            addressLines(shippingAddress.address).forEach { line in
                let label = UILabel()
                label.text = line
                label.font = .preferredFont(forTextStyle: .subheadline)
                label.textColor = .secondaryLabel
                label.numberOfLines = 0
                addressStackView.addArrangedSubview(label)
            }

            let editButton = UIButton(type: .system)
            editButton.setTitle("Edit", for: .normal)
            editButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
            editButton.addTarget(self, action: #selector(shippingAddressButtonTapped), for: .touchUpInside)
            editButton.setContentHuggingPriority(.required, for: .horizontal)

            let rowStackView = UIStackView(arrangedSubviews: [iconView, addressStackView, editButton])
            rowStackView.alignment = .top
            rowStackView.spacing = 12
            iconView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 24).isActive = true
            cardContent = rowStackView
        } else {
            let addButton = UIButton(type: .system)
            addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            addButton.setTitle("  Add shipping address", for: .normal)
            addButton.setTitleColor(.label, for: .normal)
            addButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
            addButton.contentHorizontalAlignment = .leading
            addButton.addTarget(self, action: #selector(shippingAddressButtonTapped), for: .touchUpInside)
            cardContent = addButton
        }

        return makeSection(
            title: "Shipping Address",
            content: makeCard(containing: makePaddedView(containing: cardContent))
        )
    }

    private func makeOrderSummarySection(session: CheckoutController.Session) -> UIView {
        let totals = session.totals
        let hasTaxDetails = session.taxAmounts?.isEmpty == false
        let taxAddressPrompt = taxAddressPrompt(for: session.tax?.status)
        let summaryStackView = UIStackView()
        summaryStackView.axis = .vertical
        summaryStackView.spacing = 12
        summaryStackView.addArrangedSubview(
            makeSummaryRow(
                title: "Subtotal",
                amount: totals.subtotal.amount
            )
        )

        if totals.discount.minorUnitsAmount > 0 {
            summaryStackView.addArrangedSubview(
                makeSummaryRow(
                    title: "Discount",
                    amount: "-" + totals.discount.amount,
                    color: .systemGreen
                )
            )
        }

        if let taxAddressPrompt {
            summaryStackView.addArrangedSubview(makeTaxAddressPromptRow(message: taxAddressPrompt))
        } else if totals.taxExclusive.minorUnitsAmount > 0 {
            summaryStackView.addArrangedSubview(
                makeSummaryRow(
                    title: "Tax",
                    amount: totals.taxExclusive.amount,
                    showsTaxDetailsButton: hasTaxDetails
                )
            )
        }

        summaryStackView.addArrangedSubview(makeSeparator())
        summaryStackView.addArrangedSubview(
            makeSummaryRow(
                title: "Total",
                amount: totals.total.amount,
                emphasizesText: true
            )
        )

        if taxAddressPrompt == nil && totals.taxInclusive.minorUnitsAmount > 0 {
            summaryStackView.addArrangedSubview(
                makeSummaryRow(
                    title: "Includes \(totals.taxInclusive.amount) in tax",
                    amount: "",
                    showsTaxDetailsButton: hasTaxDetails && totals.taxExclusive.minorUnitsAmount == 0
                )
            )
        }

        return makeSection(
            title: "Order Summary",
            content: makeCard(containing: makePaddedView(containing: summaryStackView))
        )
    }

    private func makeTaxAddressPromptRow(message: String) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = "Tax"
        titleLabel.textColor = .secondaryLabel
        titleLabel.font = .preferredFont(forTextStyle: .body)

        let promptLabel = UILabel()
        promptLabel.text = message
        promptLabel.textColor = .secondaryLabel
        promptLabel.font = .preferredFont(forTextStyle: .footnote)
        promptLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, promptLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.isAccessibilityElement = true
        stackView.accessibilityLabel = "Tax. \(message)"
        return stackView
    }

    private func taxAddressPrompt(for status: CheckoutController.Session.Tax.Status?) -> String? {
        switch status {
        case .requiresShippingAddress:
            return "Enter shipping address to calculate"
        case .requiresBillingAddress:
            return "Enter billing address to calculate"
        case .ready, nil:
            return nil
        }
    }

    private func makeSummaryRow(
        title: String,
        amount: String,
        color: UIColor = .secondaryLabel,
        emphasizesText: Bool = false,
        showsTaxDetailsButton: Bool = false
    ) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = emphasizesText ? .label : color
        titleLabel.font = .preferredFont(forTextStyle: emphasizesText ? .headline : .body)

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.textColor = emphasizesText ? .label : (color == .systemGreen ? color : .label)
        amountLabel.font = .preferredFont(forTextStyle: emphasizesText ? .headline : .body)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let titleStackView = UIStackView(arrangedSubviews: [titleLabel])
        titleStackView.alignment = .center
        titleStackView.spacing = 4
        if showsTaxDetailsButton {
            let infoButton = UIButton(type: .system)
            infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
            infoButton.accessibilityLabel = "Show tax details"
            infoButton.addTarget(self, action: #selector(taxDetailsButtonTapped), for: .touchUpInside)
            titleStackView.addArrangedSubview(infoButton)
        }

        let stackView = UIStackView(arrangedSubviews: [titleStackView, amountLabel])
        stackView.distribution = .equalSpacing
        return stackView
    }

    private func makePaymentMethodRow(checkout: CheckoutController) -> UIView {
        let rowView = UIButton(type: .custom)
        rowView.layer.borderColor = UIColor.separator.cgColor
        rowView.layer.borderWidth = 1
        rowView.layer.cornerRadius = 10
        rowView.addTarget(self, action: #selector(paymentMethodButtonTapped), for: .touchUpInside)

        let paymentOptionStackView = UIStackView()
        paymentOptionStackView.alignment = .center
        paymentOptionStackView.spacing = 8

        if let paymentOption = checkout.session.paymentOption {
            let imageView = UIImageView(image: paymentOption.image)
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
            paymentOptionStackView.addArrangedSubview(imageView)
            rowView.accessibilityLabel = paymentOption.label
        } else {
            rowView.accessibilityLabel = "Select payment method"
        }

        let label = UILabel()
        label.text = checkout.session.paymentOption?.label ?? "Select payment method"
        label.font = .preferredFont(forTextStyle: .subheadline)
        paymentOptionStackView.addArrangedSubview(label)

        let chevronView = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevronView.tintColor = .secondaryLabel
        chevronView.setContentHuggingPriority(.required, for: .horizontal)

        let rowStackView = UIStackView(arrangedSubviews: [paymentOptionStackView, chevronView])
        rowStackView.alignment = .center
        rowStackView.isUserInteractionEnabled = false
        rowStackView.translatesAutoresizingMaskIntoConstraints = false
        rowView.addSubview(rowStackView)

        NSLayoutConstraint.activate([
            rowStackView.topAnchor.constraint(equalTo: rowView.topAnchor, constant: 16),
            rowStackView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor, constant: 16),
            rowStackView.trailingAnchor.constraint(equalTo: rowView.trailingAnchor, constant: -16),
            rowStackView.bottomAnchor.constraint(equalTo: rowView.bottomAnchor, constant: -16),
        ])
        return rowView
    }

    private func makeCheckoutButton(checkout: CheckoutController) -> UIView {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 14
        button.addTarget(self, action: #selector(checkoutButtonTapped), for: .touchUpInside)
        button.isEnabled = !checkout.isUpdating
        button.alpha = button.isEnabled ? 1 : 0.5

        let titleLabel = UILabel()
        titleLabel.text = "Checkout"
        titleLabel.textColor = .white
        titleLabel.font = .preferredFont(forTextStyle: .headline)

        let amountLabel = UILabel()
        amountLabel.textColor = .white
        amountLabel.font = .preferredFont(forTextStyle: .headline)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)

        let formattedAmount = checkout.session.totals.total.amount
        amountLabel.text = formattedAmount
        button.accessibilityLabel = "Checkout, \(formattedAmount)"

        let stackView = UIStackView(arrangedSubviews: [titleLabel, amountLabel])
        stackView.distribution = .equalSpacing
        stackView.isUserInteractionEnabled = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: button.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -16),
        ])

        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: button.centerYAnchor),
        ])
        checkoutButton = button
        checkoutButtonContentView = stackView
        checkoutButtonActivityIndicator = activityIndicator
        updateCheckoutButtonLoadingState()
        return button
    }

    private func makeSection(title: String, content: UIView) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true

        let stackView = UIStackView(arrangedSubviews: [titleLabel, content])
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }

    private func makeCard(containing content: UIView) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .systemBackground
        cardView.layer.cornerRadius = 16
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.05
        cardView.layer.shadowRadius = 8
        cardView.layer.shadowOffset = CGSize(width: 0, height: 4)
        content.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: cardView.topAnchor),
            content.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
        ])
        return cardView
    }

    private func makePaddedView(containing content: UIView) -> UIView {
        let containerView = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
        return containerView
    }

    private func makeSeparator() -> UIView {
        let separatorView = UIView()
        separatorView.backgroundColor = .separator
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return separatorView
    }

    private func makeErrorBanner(message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.numberOfLines = 0

        let bannerView = makePaddedView(containing: label)
        bannerView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        bannerView.layer.cornerRadius = 10
        return bannerView
    }

    private func addressLines(_ address: CheckoutController.Address) -> [String] {
        var lines = [address.line1, address.line2]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        let cityStatePostalCode = [address.city, address.state, address.postalCode]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        if !cityStatePostalCode.isEmpty {
            lines.append(cityStatePostalCode)
        }
        if !address.country.isEmpty {
            lines.append(address.country)
        }
        return lines
    }

    private func removeAllArrangedSubviews(from stackView: UIStackView) {
        stackView.arrangedSubviews.forEach { arrangedSubview in
            stackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }
    }

    private func showLoadingStatus() {
        scrollView.isHidden = true
        paymentBarStackView.isHidden = true
        statusContainerView.isHidden = false
        statusLabel.text = "Loading Cart..."
        retryButton.isHidden = true
        statusActivityIndicator.startAnimating()
    }

    private func showFailureStatus() {
        scrollView.isHidden = true
        paymentBarStackView.isHidden = true
        statusContainerView.isHidden = false
        statusActivityIndicator.stopAnimating()
        statusLabel.text = "Failed to load cart."
        retryButton.isHidden = false
    }

    private func updateLoadingOverlay() {
        let isCheckoutUpdating = checkout?.isUpdating == true
        let isLoading = isCheckoutUpdating || isUpdatingShippingAddress
        loadingOverlayView.isHidden = !isLoading
        loadingOverlayView.backgroundColor = isUpdatingShippingAddress ? UIColor.black.withAlphaComponent(0.1) : .clear
        isUpdatingShippingAddress ? loadingActivityIndicator.startAnimating() : loadingActivityIndicator.stopAnimating()
        updateCheckoutButtonLoadingState()
    }

    private func updateCheckoutButtonLoadingState() {
        let isUpdating = checkout?.isUpdating == true
        checkoutButton?.isEnabled = !isUpdating
        checkoutButtonContentView?.isHidden = isUpdating
        isUpdating ? checkoutButtonActivityIndicator?.startAnimating() : checkoutButtonActivityIndicator?.stopAnimating()
    }

    private func makeAddressViewController(checkout: CheckoutController) -> AddressViewController {
        var configuration = AddressViewController.Configuration()
        configuration.title = "Shipping Address"
        configuration.buttonTitle = "Save Address"

        if let shippingAddress = checkout.session.shippingAddress {
            configuration.defaultValues = .init(
                address: .init(
                    city: shippingAddress.address.city,
                    country: shippingAddress.address.country,
                    line1: shippingAddress.address.line1,
                    line2: shippingAddress.address.line2,
                    postalCode: shippingAddress.address.postalCode,
                    state: shippingAddress.address.state
                ),
                name: shippingAddress.name
            )
        }
        return AddressViewController(configuration: configuration, delegate: self)
    }

    @objc private func closeButtonTapped() {
        closeAction()
    }

    @objc private func checkoutDetailsButtonTapped() {
        guard let checkout else { return }
        let detailsView = CheckoutSessionDetailsView(
            diagnostics: diagnostics,
            checkout: checkout
        )
        let viewController = UIHostingController(rootView: detailsView)
        if let sheetPresentationController = viewController.sheetPresentationController {
            sheetPresentationController.detents = [.medium(), .large()]
            sheetPresentationController.prefersGrabberVisible = true
        }
        present(viewController, animated: true)
    }

    @objc private func retryButtonTapped() {
        Task { await loadCheckout() }
    }

    @objc private func shippingAddressButtonTapped() {
        guard let checkout else { return }
        let addressViewController = makeAddressViewController(checkout: checkout)
        present(UINavigationController(rootViewController: addressViewController), animated: true)
    }

    @objc private func paymentMethodButtonTapped() {
        guard let checkout else { return }

        switch integrationType {
        case .flowController:
            Task {
                await checkout.getPaymentElement().present(from: self)
                renderCheckout()
            }
        case .embedded:
            let viewController = CheckoutEmbeddedPaymentViewController(
                paymentElement: checkout.getPaymentElement()
            )
            present(UINavigationController(rootViewController: viewController), animated: true)
        case .eceOnly:
            break
        }
    }

    @objc private func checkoutButtonTapped() {
        guard let checkout else { return }
        Task { @MainActor in
            let result = await checkout.confirm(from: self)
            let title: String
            let message: String
            let dismissOnAcknowledgment: Bool
            switch result {
            case .succeeded(let paymentStatus):
                title = "Success"
                message = "Payment status: \(paymentStatus)"
                dismissOnAcknowledgment = true
            case .canceled:
                title = "Canceled"
                message = "The payment was canceled."
                dismissOnAcknowledgment = false
            case .failed(let error):
                title = "Unable to complete checkout"
                message = "Localized: \(error.localizedDescription)\n\nDebug: \(String(reflecting: error))"
                dismissOnAcknowledgment = false
            }
            let alertController = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                if dismissOnAcknowledgment {
                    self?.closeAction()
                }
            })
            present(alertController, animated: true)
        }
    }

    @objc private func taxDetailsButtonTapped() {
        guard let taxAmounts = checkout?.session.taxAmounts, !taxAmounts.isEmpty else { return }
        let message = taxAmounts.map { taxAmount in
            let included = taxAmount.inclusive ? " (included)" : ""
            return "\(taxAmount.displayName)\(included): \(taxAmount.amount)"
        }.joined(separator: "\n")
        let alertController = UIAlertController(
            title: "Tax details",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "Done", style: .default))
        present(alertController, animated: true)
    }
}

extension CheckoutCartViewController: AddressViewControllerDelegate {

    func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        addressViewController.dismiss(animated: true)
        guard let checkout, let address else { return }

        Task {
            isUpdatingShippingAddress = true
            errorMessage = nil
            updateLoadingOverlay()
            do {
                try await checkout.updateShippingAddress(
                    name: address.name,
                    address: CheckoutController.Address(
                        country: address.address.country,
                        line1: address.address.line1,
                        line2: address.address.line2,
                        city: address.address.city,
                        state: address.address.state,
                        postalCode: address.address.postalCode
                    )
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isUpdatingShippingAddress = false
            renderCheckout()
        }
    }
}

@MainActor
private final class CheckoutEmbeddedPaymentViewController: UIViewController {

    private let paymentElement: PaymentElement

    init(paymentElement: PaymentElement) {
        self.paymentElement = paymentElement
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Payment Method"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let paymentElementView = paymentElement.uiView
        paymentElementView.delegate = self
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(paymentElementView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            paymentElementView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            paymentElementView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            paymentElementView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            paymentElementView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            paymentElementView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32),
        ])
    }

    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
}

extension CheckoutEmbeddedPaymentViewController: PaymentElementViewDelegate {

    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView) {
        paymentElementView.invalidateIntrinsicContentSize()
        view.layoutIfNeeded()
    }
}
