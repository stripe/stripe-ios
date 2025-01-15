//
//  EmbeddedPaymentElement+SwiftUI.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/9/25.
//

import SwiftUI
import Combine
@_spi(STP) import StripeCore

/// A view model that manages an `EmbeddedPaymentElement`.
/// Use this class to create and manage an instance of `EmbeddedPaymentElement`
@MainActor
@_spi(EmbeddedPaymentElementPrivateBeta) public final class EmbeddedPaymentElementViewModel: ObservableObject {
    enum EmbeddedPaymentElementViewModel: Error {
        /// The `EmbeddedPaymentElementViewModel` has not been loaded. Call `load()` before attempting this operation.
         case notLoaded

        /// `load()` has already been called. `load()` may only be called once.
         case multipleLoadCalls
     }
    
    // MARK: - Public properties
    
    /// Indicates whether the `EmbeddedPaymentElementViewModel` has been successfully loaded.
    @Published public private(set) var isLoaded: Bool = false
    
    /// Contains information about the customer's selected payment option.
    /// Use this to display the payment option in your own UI
    @Published public private(set) var paymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData?
    
    /// A view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
    public var view: some View {
        EmbeddedPaymentElementView(viewModel: self)
    }
    
    // MARK: - Internal properties

    private(set) var embeddedPaymentElement: EmbeddedPaymentElement?
    
    @Published var height: CGFloat = 0.0
    
    @Published var isFirstLayout: Bool = true
    
    // MARK: - Private properties
    
    private var loadTask: Task<Void, Error>?
    
    // MARK: - Public APIs

    /// Creates an empty view model. Call `load` to initialize the `EmbeddedPaymentElementViewModel`
    public init() {
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedSwiftUIProduct.self)
    }
    
    /// An asynchronous failable initializer
    /// Loads the Customer's payment methods, their default payment method, etc.
    /// - Parameter intentConfiguration: Information about the PaymentIntent or SetupIntent you will create later to complete the confirmation.
    /// - Parameter configuration: Configuration for the PaymentSheet. e.g. your business name, customer details, etc.
    /// - Note: This method may only be called once. Subsequent calls will throw `EmbeddedPaymentElementViewModel.LoadError.multipleLoadCalls`.
    ///         To support retrying after a failure, catch the error and call `load` again.
    /// - Throws: An error if loading failed.
    public func load(
        intentConfiguration: EmbeddedPaymentElement.IntentConfiguration,
        configuration: EmbeddedPaymentElement.Configuration
    ) async throws {
        // If we already have a task (whether it’s in progress or finished), throw an error:
        guard loadTask == nil else {
            throw EmbeddedPaymentElementViewModel.multipleLoadCalls
        }
        
        // Create and store the new Task
        loadTask = Task {
            let element = try await EmbeddedPaymentElement.create(
                intentConfiguration: intentConfiguration,
                configuration: configuration
            )
            self.embeddedPaymentElement = element
            self.embeddedPaymentElement?.delegate = self
            self.paymentOption = element.paymentOption
            self.isLoaded = true
        }

        do {
            try await loadTask?.value
        } catch {
            // Reset loadTask to allow for load retries after errors
            loadTask = nil
            throw error
        }
    }
    
    /// Call this method when the IntentConfiguration values you used to initialize `EmbeddedPaymentElementViewModel` (amount, currency, etc.) change.
    /// This ensures the appropriate payment methods are displayed, collect the right fields, etc.
    /// - Parameter intentConfiguration: An updated IntentConfiguration.
    /// - Returns: The result of the update. Any calls made to `update` before this call that are still in progress will return a `.canceled` result.
    /// - Note: Upon completion, `paymentOption` may become nil if it's no longer available.
    public func update(
        intentConfiguration: EmbeddedPaymentElement.IntentConfiguration
    ) async -> EmbeddedPaymentElement.UpdateResult {
        guard let embeddedPaymentElement = embeddedPaymentElement else {
            return .failed(error: EmbeddedPaymentElementViewModel.notLoaded)
        }
        
        return await embeddedPaymentElement.update(intentConfiguration: intentConfiguration)
    }
    
    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method requires that the last call to `update` succeeded. If the last `update` call failed, this call will fail. If this method is called while a call to `update` is in progress, it waits until the `update` call completes.
    public func confirm() async -> EmbeddedPaymentElementResult {
        guard let embeddedPaymentElement = embeddedPaymentElement else {
            return .failed(error: EmbeddedPaymentElementViewModel.notLoaded)
        }
        
        let result = await embeddedPaymentElement.confirm()
        return result
    }
    
    /// Sets the currently selected payment option to `nil`.
    public func clearPaymentOption() {
        embeddedPaymentElement?.clearPaymentOption()
        self.paymentOption = embeddedPaymentElement?.paymentOption
    }
    
#if DEBUG
    public func testHeightChange() {
        embeddedPaymentElement?.testHeightChange()
    }
#endif
}

// MARK: EmbeddedPaymentElementDelegate

extension EmbeddedPaymentElementViewModel: EmbeddedPaymentElementDelegate {
    public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        // no-op, `height` is updated in `EmbeddedViewRepresentable`
    }
    
    public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
        self.paymentOption = embeddedPaymentElement.paymentOption
    }
}

// MARK: Internal

/// This View takes an `EmbeddedPaymentElementViewModel` and creates an instance of `EmbeddedViewRepresentable`,
/// manages its lifecycle, and displays it within your SwiftUI view hierarchy.
struct EmbeddedPaymentElementView: View {
    @ObservedObject private var viewModel: EmbeddedPaymentElementViewModel
    
    public init(viewModel: EmbeddedPaymentElementViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EmbeddedViewRepresentable(viewModel: viewModel)
            .frame(height: viewModel.height)
    }
}

struct EmbeddedViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: EmbeddedPaymentElementViewModel
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else { return containerView }
        
        embeddedPaymentElement.presentingViewController = context.coordinator.topMostViewController()
        
        let paymentElementView = embeddedPaymentElement.view
        paymentElementView.layoutMargins = .zero
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(paymentElementView)
        
        let bottomConstraint = paymentElementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomConstraint
        ])
        
        return containerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the presenting view controller in case it has changed
        viewModel.embeddedPaymentElement?.presentingViewController = context.coordinator.topMostViewController()
        
        DispatchQueue.main.async {
            let newHeight = uiView.systemLayoutSizeFitting(CGSize(width: uiView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
            if self.viewModel.isFirstLayout {
                // No animation for the first layout
                self.viewModel.height = newHeight
                self.viewModel.isFirstLayout = false
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.viewModel.height = newHeight
                }
            }
        }
    }

    public class Coordinator: NSObject {
        var parent: EmbeddedViewRepresentable
        
        init(_ parent: EmbeddedViewRepresentable) {
            self.parent = parent
        }
        
        func topMostViewController() -> UIViewController {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let window = scene.windows.first(where: { $0.isKeyWindow }),
                let rootViewController = window.rootViewController
            else {
                return UIViewController()
            }
            return findTopViewController(from: rootViewController)
        }

        private func findTopViewController(from rootVC: UIViewController) -> UIViewController {
            if let presented = rootVC.presentedViewController {
                return findTopViewController(from: presented)
            }
            if let nav = rootVC as? UINavigationController,
               let visible = nav.visibleViewController {
                return findTopViewController(from: visible)
            }
            if let tab = rootVC as? UITabBarController,
               let selected = tab.selectedViewController {
                return findTopViewController(from: selected)
            }
            return rootVC
        }
    }
}

final class EmbeddedSwiftUIProduct: STPAnalyticsProtocol {
    public static var stp_analyticsIdentifier: String {
        return "EmbeddedPaymentElement_SwiftUI"
    }
}
