import Combine
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@MainActor
final class CheckoutSheetModel: NSObject, ObservableObject {
    static let compactDetentIdentifier = UISheetPresentationController.Detent.Identifier("checkout_sheet_fitted")
    private var compactContentHeight: CGFloat = 240
    private var compactActionsHeight: CGFloat = 160
    enum Task: Hashable { case contact, shipping, payment }

    let checkout: CheckoutController
    let configuration: CheckoutSheet.Configuration
    @Published var activeTask: Task?
    @Published var isReview = false
    @Published var isWorking = false
    @Published var errorMessage: String?
    @Published var completedPaymentStatus: CheckoutController.Session.Status.PaymentStatus?
    @Published var emailDraft = ""
    @Published var promotionCode = ""
    @Published var addressRevision = 0
    private(set) var addressSection: AddressSectionElement!
    weak var navigationController: UINavigationController?
    private weak var taskViewController: UIViewController?
    private weak var paymentViewController: UIViewController?
    private var subscriptions = Set<AnyCancellable>()
    var onFinish: ((CheckoutController.ConfirmResult) -> Void)?

    init(checkout: CheckoutController, configuration: CheckoutSheet.Configuration) async {
        self.checkout = checkout
        self.configuration = configuration
        super.init()
        await AddressSpecProvider.shared.loadAddressSpecs()
        let shipping = checkout.session.shippingAddress
        addressSection = AddressSectionElement(
            countries: checkout.session.allowedShippingCountries,
            defaults: .init(
                name: shipping?.name,
                address: .init(
                    city: shipping?.address.city,
                    country: shipping?.address.country,
                    line1: shipping?.address.line1,
                    line2: shipping?.address.line2,
                    postalCode: shipping?.address.postalCode,
                    state: shipping?.address.state
                )
            ),
            additionalFields: .init(name: .enabled()),
            theme: configuration.appearance.asElementsTheme,
            presentAutoComplete: { [weak self] in self?.presentAddressSearch() }
        )
        addressSection.delegate = self
        checkout.getExpressCheckoutElement().uiView.onConfirmStarted = { [weak self] in
            self?.errorMessage = nil
            self?.isWorking = true
            self?.navigationController?.isModalInPresentation = true
        }
        // Checkout emits whenever an element, wallet, or merchant changes session state.
        checkout.$session.dropFirst().sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
        checkout.$isUpdating.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &subscriptions)
    }

    var tasks: [Task] {
        var tasks: [Task] = [.contact]
        if checkout.session.requiresShippingAddress { tasks.append(.shipping) }
        if needsPaymentMethod { tasks.append(.payment) }
        return tasks
    }

    var needsPaymentMethod: Bool {
        !checkout.session.noPaymentRequired && checkout.session.totals.total.minorUnitsAmount > 0
    }

    var firstIncompleteTask: Task? { tasks.first { !isComplete($0) } }
    var canConfirm: Bool { firstIncompleteTask == nil && checkout.sessionIsOpen && !isBusy }
    var isBusy: Bool { isWorking || checkout.isUpdating }
    var emailIsValid: Bool {
        STPEmailAddressValidator.stringIsValidEmailAddress(emailDraft.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    var addressIsValid: Bool { addressSection.validationState.isValid && addressSection.line1?.text.nonEmpty != nil }
    var hasWallets: Bool {
        guard let express = checkout.configuration.expressCheckoutElement else { return false }
        return !ExpressCheckoutElementUtilities.resolveButtons(for: checkout.session, configuration: express).isEmpty
    }

    func isComplete(_ task: Task) -> Bool {
        switch task {
        case .contact: return checkout.session.email?.nonEmpty != nil
        case .shipping: return checkout.session.shippingAddress?.shippingDetailsParams != nil
        case .payment: return checkout.session.paymentOption != nil
        }
    }

    func canEdit(_ task: Task) -> Bool {
        if task == .contact && checkout.session.serverEmail != nil { return false }
        guard let index = tasks.firstIndex(of: task) else { return false }
        return tasks.prefix(index).allSatisfy(isComplete)
    }

    func resetPresentation() {
        isReview =
            firstIncompleteTask == nil || checkout.session.paymentOption != nil
            || checkout.session.shippingAddress != nil
        completedPaymentStatus = nil
        errorMessage = nil
        emailDraft = checkout.session.email ?? ""
        promotionCode = ""
        activeTask = nil
    }

    func configureNavigationItem(_ controller: UIViewController) {
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in self?.close() }
        )
        controller.navigationItem.rightBarButtonItem?.accessibilityLabel = CheckoutSheetStrings.close
        controller.navigationItem.rightBarButtonItem?.accessibilityIdentifier = "checkout_sheet_close"
        controller.navigationItem.backButtonDisplayMode = .minimal
    }

    func updateCompactHeight(content: CGFloat? = nil, actions: CGFloat? = nil) {
        if let content, content > 0, abs(content - compactContentHeight) > 1 {
            compactContentHeight = content
        } else if let actions, actions > 0, abs(actions - compactActionsHeight) > 1 {
            compactActionsHeight = actions
        } else {
            return
        }
        // SwiftUI can report zero when its view leaves navigation. Keep the last fitted size.
        // Resolve the new size after the layout pass that supplied these measurements.
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.sheetPresentationController?.invalidateDetents()
        }
    }

    func updateCompactDetent() {
        guard let sheet = navigationController?.sheetPresentationController else { return }
        sheet.detents = [
            .custom(identifier: Self.compactDetentIdentifier) { [weak self] context in
                guard let self else { return nil }
                return min(self.compactContentHeight + self.compactActionsHeight + 64, context.maximumDetentValue)
            },
            .large(),
        ]
    }

    func showTasks(startingAt task: Task? = nil) {
        guard !isBusy, let navigationController else { return }
        activeTask = task ?? firstIncompleteTask ?? tasks.last
        errorMessage = nil
        emailDraft = checkout.session.email ?? ""
        let controller = UIHostingController(rootView: CheckoutSheetTasksView(model: self))
        controller.title = checkout.effectiveMerchantDisplayName
        controller.view.backgroundColor = configuration.appearance.colors.background
        configureNavigationItem(controller)
        taskViewController = controller
        navigationController.pushViewController(controller, animated: true)
    }

    func selectTask(_ task: Task) {
        guard !isBusy, canEdit(task) else { return }
        activeTask = activeTask == task ? nil : task
        errorMessage = nil
    }

    func saveContact() async {
        guard emailIsValid, !isBusy, checkout.session.serverEmail == nil else { return }
        await perform {
            try await self.checkout.updateEmail(self.emailDraft.trimmingCharacters(in: .whitespacesAndNewlines))
            self.advance(after: .contact)
        }
    }

    func saveShipping() async {
        guard addressIsValid, !isBusy else { return }
        let details = addressSection.addressDetails
        await perform {
            try await self.checkout.getShippingAddressElement().save(
                addressDetails: .init(
                    address: .init(
                        city: details.address.city?.nonEmpty,
                        country: self.addressSection.selectedCountryCode,
                        line1: details.address.line1 ?? "",
                        line2: details.address.line2?.nonEmpty,
                        postalCode: details.address.postalCode?.nonEmpty,
                        state: details.address.state?.nonEmpty
                    ),
                    name: details.name?.nonEmpty
                )
            )
            self.advance(after: .shipping)
        }
    }

    func advance(after task: Task) {
        guard isComplete(task) else { return }
        if firstIncompleteTask == nil {
            returnToReview()
        } else {
            activeTask = firstIncompleteTask
        }
    }

    func returnToReview() {
        isReview = true
        activeTask = nil
        navigationController?.view.endEditing(true)
        navigationController?.popToRootViewController(animated: true)
    }

    func applyPromotionCode() async {
        let code = promotionCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty, !isBusy else { return }
        await perform {
            try await self.checkout.applyPromotionCode(code)
            self.promotionCode = ""
        }
    }

    func removePromotionCode() async {
        guard !isBusy else { return }
        await perform { try await self.checkout.removePromotionCode() }
    }

    private func perform(_ operation: () async throws -> Void) async {
        isWorking = true
        errorMessage = nil
        defer { isWorking = false }
        do { try await operation() } catch { errorMessage = error.localizedDescription }
    }

    func confirm() async {
        guard canConfirm, let presenter = navigationController?.topViewController else { return }
        isWorking = true
        errorMessage = nil
        navigationController?.isModalInPresentation = true
        handleConfirmationResult(await checkout.confirm(from: presenter))
    }

    func handleConfirmationResult(_ result: CheckoutController.ConfirmResult) {
        isWorking = false
        navigationController?.isModalInPresentation = false
        switch result {
        case .completed(let status):
            completedPaymentStatus = status
            returnToReview()
        case .canceled: break
        case .failed(let error): errorMessage = error.localizedDescription
        }
    }

    func close() {
        guard !isBusy else { return }
        if let completedPaymentStatus {
            onFinish?(.completed(paymentStatus: completedPaymentStatus))
        } else {
            onFinish?(.canceled)
        }
    }

    private func presentAddressSearch() {
        guard let navigationController, !isBusy else { return }
        var config = AddressViewController.Configuration()
        config.apiClient = checkout.apiClient
        config.allowedCountries = checkout.session.allowedShippingCountries ?? []
        config.appearance = configuration.appearance
        let controller = AutoCompleteViewController(
            configuration: config,
            initialLine1Text: addressSection.line1?.text,
            selectedCountry: addressSection.selectedCountryCode,
            addressSpecProvider: .shared,
            keyboardAlreadyShowing: navigationController.view.firstResponder() != nil,
            useAutocompleteEndpoints: checkout.session.elementsSession.shouldUseAutocompleteProxyEndpoints
        )
        controller.delegate = self
        navigationController.pushViewController(controller, animated: true)
    }
}

// These legacy UI delegates call synchronously on the main thread. Keep their callbacks actor-isolated.
@available(iOS 16.0, *)
extension CheckoutSheetModel: @preconcurrency ElementDelegate {
    func didUpdate(element: Element) { addressRevision += 1 }
    func continueToNextField(element: Element) {}
}

@available(iOS 16.0, *)
extension CheckoutSheetModel: @preconcurrency AutoCompleteViewControllerDelegate {
    func didSelectManualEntry(_ line1: String) {
        navigationController?.popViewController(animated: true)
        addressSection.beginManualEntry(with: line1)
    }

    func didSelectAddress(_ address: PaymentSheet.Address?) {
        navigationController?.popViewController(animated: true)
        guard let address else { return }
        guard let country = address.country, addressSection.countryCodes.contains(country) else { return }
        addressSection.setAddress(address.addressSectionAddress)
        addressRevision += 1
    }
}

@available(iOS 16.0, *)
extension CheckoutSheetModel: EmbeddedPaymentElementUIHost {
    var isPresentingPaymentUI: Bool { paymentViewController != nil }

    func presentPaymentUI(_ viewController: BottomSheetViewController) {
        guard !isBusy, paymentViewController == nil, let navigationController else { return }
        paymentViewController = viewController
        navigationController.isModalInPresentation = true
        viewController.navigationItem.hidesBackButton = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func dismissPaymentUI(completion: (() -> Void)?) {
        guard let navigationController, let taskViewController else {
            completion?()
            return
        }
        navigationController.popToViewController(taskViewController, animated: true)
        // Keep the editor guard set until it has left navigation, just as modal element presentation does.
        if let transition = navigationController.transitionCoordinator {
            transition.animate(alongsideTransition: nil) { [weak self] _ in
                self?.paymentViewController = nil
                self?.navigationController?.isModalInPresentation = false
                completion?()
            }
        } else {
            paymentViewController = nil
            navigationController.isModalInPresentation = false
            completion?()
        }
    }
}

@available(iOS 16.0, *)
extension CheckoutSheetModel: UINavigationControllerDelegate, UISheetPresentationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        let isRoot = navigationController.viewControllers.first === viewController
        navigationController.setNavigationBarHidden(viewController is BottomSheetViewController, animated: animated)
        navigationController.interactivePopGestureRecognizer?.isEnabled = paymentViewController == nil && !isBusy
        navigationController.sheetPresentationController?.animateChanges {
            navigationController.sheetPresentationController?.selectedDetentIdentifier =
                isRoot ? Self.compactDetentIdentifier : .large
        }
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !isBusy && !isPresentingPaymentUI
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { close() }
}
