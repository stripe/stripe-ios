@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

/// The compact express and review composition, ported from Verde's Accordion stack.
@available(iOS 16.0, *)
struct CheckoutSheetRootView: View {
    @ObservedObject var model: CheckoutSheetModel
    @ObservedObject private var checkout: CheckoutController
    @State private var showsSummary = false
    @ScaledMetric(relativeTo: .largeTitle) private var amountFontSize = 40
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(model: CheckoutSheetModel) {
        self.model = model
        checkout = model.checkout
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let status = model.completedPaymentStatus {
                    confirmation(status)
                } else {
                    masthead
                    if showsSummary { orderSummary.transition(.opacity) }
                    if model.configuration.allowsAdaptivePricing, let selector = checkout.getCurrencySelectorElement() {
                        selector.view
                    }
                    if model.isReview {
                        reviewRows
                    }
                    if checkout.session.allowsPromotionCodes { promotionControl }
                    CheckoutSheetErrorView(message: model.errorMessage)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: CheckoutSheetContentHeightKey.self, value: geometry.size.height)
                }
            )
        }
        .background(Color(uiColor: model.configuration.appearance.colors.background).ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .onPreferenceChange(CheckoutSheetContentHeightKey.self) { height in
            if !showsSummary { model.updateCompactHeight(content: height) }
        }
        .onPreferenceChange(CheckoutSheetActionsHeightKey.self) { model.updateCompactHeight(actions: $0) }
        .onChange(of: dynamicTypeSize) { size in
            if size.isAccessibilitySize {
                model.navigationController?.sheetPresentationController?.selectedDetentIdentifier = .large
            }
        }
        .onAppear {
            if dynamicTypeSize.isAccessibilitySize {
                model.navigationController?.sheetPresentationController?.selectedDetentIdentifier = .large
            }
        }
        .accessibilityIdentifier("checkout_sheet")
    }

    private var masthead: some View {
        VStack(spacing: 8) {
            if let logo = model.configuration.merchantLogo {
                SwiftUI.Image(uiImage: logo).resizable().scaledToFit().frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.bottom, 4)
                    .accessibilityHidden(true)
            }
            Text(checkout.effectiveMerchantDisplayName).font(.title3.weight(.semibold)).foregroundColor(.secondary)
            Text(checkout.session.totals.total.amount)
                .font(.system(size: amountFontSize, weight: .semibold)).monospacedDigit()
                .accessibilityIdentifier("checkout_sheet_total")
            Button {
                showsSummary.toggle()
                if showsSummary {
                    model.navigationController?.sheetPresentationController?.animateChanges {
                        model.navigationController?.sheetPresentationController?.selectedDetentIdentifier = .large
                    }
                }
            } label: {
                Label(CheckoutSheetStrings.orderSummary, systemImage: showsSummary ? "chevron.up" : "chevron.down")
                    .font(.footnote.weight(.medium)).foregroundColor(.secondary)
                    .padding(.horizontal, 16).frame(minHeight: 44)
                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .opacity(checkout.isUpdating ? 0.6 : 1)
    }

    private var orderSummary: some View {
        VStack(spacing: 16) {
            ForEach(checkout.session.orderSummaryItems) { group in
                switch group {
                case .oneTimePrice(let price):
                    ForEach(price.items) { item in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.displayName).font(.body)
                                Text("\(CheckoutSheetStrings.quantity): \(item.quantity)").font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(item.amountDetails.total.amount).monospacedDigit()
                        }
                    }
                }
            }
            Divider()
            amountRow(CheckoutSheetStrings.subtotal, checkout.session.totals.subtotal.amount)
            if checkout.session.totals.discount.minorUnitsAmount > 0 {
                amountRow(CheckoutSheetStrings.discount, "−\(checkout.session.totals.discount.amount)")
            }
            amountRow(CheckoutSheetStrings.tax, checkout.session.totals.taxExclusive.amount)
            if checkout.session.totals.taxInclusive.minorUnitsAmount > 0 {
                amountRow(CheckoutSheetStrings.taxIncluded, checkout.session.totals.taxInclusive.amount)
            }
            Divider()
            amountRow(CheckoutSheetStrings.total, checkout.session.totals.total.amount).fontWeight(.semibold)
        }
        .font(.subheadline)
        .padding(16)
        .background(
            Color(uiColor: model.configuration.appearance.colors.componentBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private func amountRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
            Spacer()
            Text(value).monospacedDigit()
        }
    }

    private var reviewRows: some View {
        VStack(spacing: 12) {
            ForEach(model.tasks, id: \.self) { task in
                if model.isComplete(task) {
                    Button {
                        model.showTasks(startingAt: task)
                    } label: {
                        CheckoutSheetTaskRow(model: model, task: task, expanded: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("checkout_sheet_review_\(task)")
                    .disabled(!model.canEdit(task))
                }
            }
        }
    }

    private var promotionControl: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(checkout.session.discountAmounts.enumerated()), id: \.offset) { _, discount in
                HStack {
                    Text(discount.promotionCode ?? discount.displayName).font(.subheadline)
                    Spacer()
                    if discount.promotionCode != nil {
                        Button(CheckoutSheetStrings.remove) { Task { await model.removePromotionCode() } }
                            .font(.subheadline).frame(minHeight: 44)
                    }
                }
            }
            HStack {
                TextField(CheckoutSheetStrings.promotionCode, text: $model.promotionCode)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                    .submitLabel(.done).onSubmit { Task { await model.applyPromotionCode() } }
                Button(CheckoutSheetStrings.apply) { Task { await model.applyPromotionCode() } }
                    .disabled(model.promotionCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, 16)
            .background(
                Color(uiColor: model.configuration.appearance.colors.componentBackground),
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
        .disabled(model.isBusy)
    }

    private var actions: some View {
        VStack(spacing: 0) {
            if model.completedPaymentStatus != nil {
                CheckoutSheetAction(title: CheckoutSheetStrings.done, model: model, action: model.close)
                    .padding(.bottom, 8)
            } else {
                if model.hasWallets && (!model.isReview || model.firstIncompleteTask != nil) {
                    checkout.getExpressCheckoutElement().view.padding(.bottom, 8)
                }
                if model.isReview && model.firstIncompleteTask == nil {
                    if let mandate = checkout.session.paymentOption?.mandateText {
                        CheckoutSheetMandateView(text: mandate).padding(.bottom, 12)
                    }
                    CheckoutSheetAction(title: CheckoutSheetStrings.payNow, model: model, enabled: model.canConfirm) {
                        Task { await model.confirm() }
                    }.padding(.bottom, 8)
                } else {
                    CheckoutSheetAction(
                        title: model.hasWallets
                            ? CheckoutSheetStrings.payAnotherWay : CheckoutSheetStrings.continueCheckout,
                        model: model,
                        subdued: true
                    ) { model.showTasks() }.padding(.bottom, 8)
                }
            }
            HStack(spacing: 4) {
                Text(CheckoutSheetStrings.poweredBy).font(.caption)
                SwiftUI.Image(uiImage: Image.stripe_wordmark.makeImage()).renderingMode(.template)
                    .resizable().scaledToFit().frame(width: 33, height: 15)
            }
            .foregroundColor(.secondary).frame(minHeight: 28)
            .accessibilityElement(children: .ignore).accessibilityLabel(CheckoutSheetStrings.poweredByStripe)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
        .background(Color(uiColor: model.configuration.appearance.colors.background))
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: CheckoutSheetActionsHeightKey.self, value: geometry.size.height)
            }
        )
        .disabled(model.isBusy)
    }

    private func confirmation(_ status: CheckoutController.Session.Status.PaymentStatus) -> some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundColor(.green)
                .accessibilityHidden(true)
            Text(status == .paid ? CheckoutSheetStrings.paymentComplete : CheckoutSheetStrings.checkoutComplete).font(
                .title2.weight(.semibold)
            )
            Text(checkout.session.totals.total.amount).font(.title).monospacedDigit()
            Text(checkout.effectiveMerchantDisplayName).foregroundColor(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 24)
    }
}

@available(iOS 16.0, *)
struct CheckoutSheetTasksView: View {
    @ObservedObject var model: CheckoutSheetModel
    @ObservedObject private var checkout: CheckoutController
    @FocusState private var emailFocused: Bool

    init(model: CheckoutSheetModel) {
        self.model = model
        checkout = model.checkout
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(model.tasks, id: \.self) { task in
                        VStack(spacing: 0) {
                            Button {
                                model.selectTask(task)
                            } label: {
                                CheckoutSheetTaskRow(model: model, task: task, expanded: model.activeTask == task)
                            }
                            .buttonStyle(.plain).disabled(!model.canEdit(task) || model.isBusy)
                            if model.activeTask == task {
                                taskBody(task).padding(.horizontal, 16).padding(.bottom, 16)
                                    .transition(.opacity)
                            }
                        }
                        .background(
                            Color(uiColor: model.configuration.appearance.colors.componentBackground),
                            in: RoundedRectangle(cornerRadius: 20)
                        )
                        .id(task)
                    }
                    CheckoutSheetErrorView(message: model.errorMessage)
                }.padding(.horizontal, 20).padding(.vertical, 24)
            }
            .onChange(of: model.activeTask) { task in
                if let task { proxy.scrollTo(task, anchor: .top) }
                emailFocused = task == .contact
            }
        }
        .background(Color(uiColor: model.configuration.appearance.colors.background).ignoresSafeArea())
        .disabled(model.isBusy)
        .onAppear { emailFocused = model.activeTask == .contact }
        .accessibilityIdentifier("checkout_sheet_tasks")
    }

    @ViewBuilder private func taskBody(_ task: CheckoutSheetModel.Task) -> some View {
        switch task {
        case .contact:
            VStack(spacing: 16) {
                TextField(CheckoutSheetStrings.email, text: $model.emailDraft)
                    .font(.body).keyboardType(.emailAddress).textContentType(.emailAddress)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().focused($emailFocused)
                    .padding(16).background(Color(uiColor: .tertiarySystemFill), in: RoundedRectangle(cornerRadius: 12))
                    .submitLabel(.continue).onSubmit { Task { await model.saveContact() } }
                    .accessibilityIdentifier("checkout_sheet_email")
                CheckoutSheetAction(
                    title: checkout.session.requiresShippingAddress
                        ? CheckoutSheetStrings.continueToShipping : CheckoutSheetStrings.continueToPayment,
                    model: model,
                    enabled: model.emailIsValid
                ) { Task { await model.saveContact() } }
            }
        case .shipping:
            VStack(spacing: 16) {
                CheckoutSheetElementView(view: model.addressSection.view, revision: model.addressRevision)
                    .frame(maxWidth: .infinity)
                CheckoutSheetAction(
                    title: CheckoutSheetStrings.continueToPayment,
                    model: model,
                    enabled: model.addressIsValid
                ) {
                    Task { await model.saveShipping() }
                }
            }
        case .payment:
            VStack(spacing: 16) {
                checkout.getPaymentElement().view
                CheckoutSheetAction(
                    title: CheckoutSheetStrings.review,
                    model: model,
                    enabled: checkout.session.paymentOption != nil
                ) {
                    model.advance(after: .payment)
                }
            }
        }
    }
}

@available(iOS 16.0, *)
private struct CheckoutSheetTaskRow: View {
    @ObservedObject var model: CheckoutSheetModel
    let task: CheckoutSheetModel.Task
    let expanded: Bool

    var body: some View {
        HStack(spacing: 16) {
            Group {
                if task == .payment, let payment = model.checkout.session.paymentOption {
                    SwiftUI.Image(uiImage: payment.image).resizable().scaledToFit().frame(width: 40, height: 32)
                } else {
                    SwiftUI.Image(
                        systemName: task == .contact ? "person" : task == .shipping ? "shippingbox" : "creditcard"
                    )
                    .font(.body).foregroundColor(.secondary).frame(width: 40, height: 40)
                    .background(Color(uiColor: .tertiarySystemFill), in: Circle())
                }
            }.accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.callout).foregroundColor(expanded ? .primary : .secondary)
                if !expanded, let summary { Text(summary).font(.callout.weight(.medium)).foregroundColor(.primary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
            if model.canEdit(task) {
                SwiftUI.Image(systemName: expanded ? "chevron.down" : "chevron.right").font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .multilineTextAlignment(.leading).padding(16).frame(minHeight: 72)
        .background(
            Color(uiColor: model.configuration.appearance.colors.componentBackground),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        switch task {
        case .contact: return CheckoutSheetStrings.contact
        case .shipping:
            return model.isComplete(task) ? CheckoutSheetStrings.shipTo : CheckoutSheetStrings.shippingAddress
        case .payment: return CheckoutSheetStrings.paymentMethod
        }
    }

    private var summary: String? {
        switch task {
        case .contact: return model.checkout.session.email
        case .shipping:
            guard let shipping = model.checkout.session.shippingAddress else { return nil }
            return [shipping.name, shipping.address.line1, shipping.address.city, shipping.address.postalCode]
                .compactMap { $0?.nonEmpty }.joined(separator: ", ")
        case .payment: return model.checkout.session.paymentOption?.label
        }
    }
}

@available(iOS 16.0, *)
private struct CheckoutSheetAction: View {
    let title: String
    @ObservedObject var model: CheckoutSheetModel
    var enabled = true
    var subdued = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer(minLength: 0)
                if model.isWorking { ProgressView().tint(foreground) }
                Text(title).font(.body.weight(.semibold)).multilineTextAlignment(.center)
                Spacer(minLength: 0)
            }
            .foregroundColor(foreground).padding(.horizontal, 20).padding(.vertical, 16).frame(minHeight: 55)
            .background(background, in: Capsule())
            .opacity(enabled && !model.isBusy ? 1 : 0.5)
        }
        .buttonStyle(.plain).disabled(!enabled || model.isBusy)
    }

    private var foreground: Color {
        Color(
            uiColor: subdued
                ? model.configuration.appearance.colors.text
                : model.configuration.appearance.primaryButton.textColor ?? .systemBackground
        )
    }
    private var background: Color {
        Color(
            uiColor: subdued
                ? .tertiarySystemFill
                : model.configuration.appearance.primaryButton.backgroundColor
                    ?? model.configuration.appearance.colors.primary
        )
    }
}

@available(iOS 16.0, *)
private struct CheckoutSheetErrorView: View {
    let message: String?
    var body: some View {
        if let message {
            Text(message).font(.subheadline).foregroundColor(.red).frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("checkout_sheet_error")
        }
    }
}

@available(iOS 16.0, *)
private struct CheckoutSheetElementView: UIViewRepresentable {
    let view: UIView
    let revision: Int
    func makeUIView(context: Context) -> CheckoutSheetElementContainer { .init(elementView: view) }
    func updateUIView(_ uiView: CheckoutSheetElementContainer, context: Context) { uiView.setNeedsLayout() }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: CheckoutSheetElementContainer, context: Context) -> CGSize?
    {
        guard let width = proposal.width, width.isFinite else { return nil }
        guard width > 0 else { return .zero }
        return uiView.fittingSize(width: width)
    }
}

@available(iOS 16.0, *)
final class CheckoutSheetElementContainer: UIView {
    let elementView: UIView

    init(elementView: UIView) {
        self.elementView = elementView
        super.init(frame: .zero)
        elementView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(elementView)
        let trailing = elementView.trailingAnchor.constraint(equalTo: trailingAnchor)
        // SwiftUI probes zero width during layout. Let the wrapper yield instead of breaking field constraints.
        trailing.priority = UILayoutPriority(999)
        let bottom = elementView.bottomAnchor.constraint(equalTo: bottomAnchor)
        // The form can expand before SwiftUI replaces its previously measured height.
        bottom.priority = .defaultHigh
        NSLayoutConstraint.activate([
            elementView.topAnchor.constraint(equalTo: topAnchor),
            elementView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailing,
            bottom,
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func fittingSize(width: CGFloat) -> CGSize {
        let size = systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: size.height)
    }

}

@available(iOS 16.0, *)
private struct CheckoutSheetMandateView: UIViewRepresentable {
    let text: NSAttributedString
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        return view
    }
    func updateUIView(_ uiView: UITextView, context: Context) { uiView.attributedText = text }
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        return uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
    }
}

private struct CheckoutSheetContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct CheckoutSheetActionsHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

enum CheckoutSheetStrings {
    static var close: String { STPLocalizedString("Close", "Close Checkout Sheet") }
    static var done: String { STPLocalizedString("Done", "Dismiss checkout confirmation") }
    static var orderSummary: String { STPLocalizedString("Order summary", "Checkout order summary disclosure") }
    static var quantity: String { STPLocalizedString("Quantity", "Order item quantity") }
    static var subtotal: String { STPLocalizedString("Subtotal", "Checkout subtotal") }
    static var discount: String { STPLocalizedString("Discount", "Checkout discount") }
    static var tax: String { STPLocalizedString("Tax", "Checkout exclusive tax") }
    static var taxIncluded: String { STPLocalizedString("Tax included", "Checkout inclusive tax") }
    static var total: String { STPLocalizedString("Total", "Checkout total") }
    static var promotionCode: String { STPLocalizedString("Promotion code", "Checkout promotion code field") }
    static var apply: String { STPLocalizedString("Apply", "Apply a promotion code") }
    static var remove: String { STPLocalizedString("Remove", "Remove a promotion code") }
    static var payNow: String { STPLocalizedString("Pay now", "Confirm a Checkout Session") }
    static var payAnotherWay: String {
        STPLocalizedString("Pay another way", "Enter checkout details instead of using a wallet")
    }
    static var continueCheckout: String { STPLocalizedString("Continue checkout", "Enter checkout details") }
    static var continueToShipping: String {
        STPLocalizedString("Continue to shipping", "Continue after entering contact information")
    }
    static var continueToPayment: String {
        STPLocalizedString("Continue to payment", "Continue after entering customer details")
    }
    static var review: String { STPLocalizedString("Review", "Review the checkout before paying") }
    static var email: String { STPLocalizedString("Email", "Customer email field") }
    static var contact: String { STPLocalizedString("Contact information", "Checkout contact task") }
    static var shipTo: String { STPLocalizedString("Ship to", "Checkout shipping address review") }
    static var shippingAddress: String { STPLocalizedString("Shipping address", "Checkout shipping address task") }
    static var paymentMethod: String { STPLocalizedString("Payment method", "Checkout payment method task") }
    static var poweredByStripe: String { STPLocalizedString("Powered by Stripe", "Checkout Sheet footer") }
    static var poweredBy: String { STPLocalizedString("Powered by", "Label before the Stripe wordmark") }
    static var paymentComplete: String {
        STPLocalizedString("Payment complete", "Successful payment confirmation heading")
    }
    static var checkoutComplete: String {
        STPLocalizedString("Checkout complete", "Completed checkout confirmation heading")
    }
}
