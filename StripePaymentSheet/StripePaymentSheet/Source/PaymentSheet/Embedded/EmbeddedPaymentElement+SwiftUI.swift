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
    enum EmbeddedPaymentElementError: Error {
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
    @Published public internal(set) var paymentOption: EmbeddedPaymentElement.PaymentOptionDisplayData?
    
    /// The result of the `confirm()` call.
    ///
    /// This value is `nil` until `confirm()` is called. After a call to `confirm()`, this property contains the result of the confirmation,
    /// which can be either a successful, failed, or canceled payment. Inspect the value to determine the outcome and handle it accordingly.
    @Published public var confirmationResult: EmbeddedPaymentElementResult?
    
    /// A view that displays payment methods. It can present a sheet to collect more details or display saved payment methods.
    public var view: some View {
        EmbeddedPaymentElementView(viewModel: self)
    }
    
    // MARK: - Internal properties

    private(set) var embeddedPaymentElement: EmbeddedPaymentElement?
    
    // MARK: - Private properties
    
    private var loadTask: Task<Void, Error>?
    
    // MARK: - Public APIs

    /// Creates an empty view model. Call `load` to initialize the `EmbeddedPaymentElementViewModel`.
    public init() {}
    
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
            throw EmbeddedPaymentElementError.multipleLoadCalls
        }
        
        // Create and store the new Task
        loadTask = Task {
            let element = try await EmbeddedPaymentElement.create(
                intentConfiguration: intentConfiguration,
                configuration: configuration
            )
            self.embeddedPaymentElement = element
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
            return .failed(error: EmbeddedPaymentElementError.notLoaded)
        }
        
        return await embeddedPaymentElement.update(intentConfiguration: intentConfiguration)
    }
    
    /// Completes the payment or setup.
    /// - Returns: The result of the payment after any presented view controllers are dismissed.
    /// - Note: This method requires that the last call to `update` succeeded. If the last `update` call failed, this call will fail. If this method is called while a call to `update` is in progress, it waits until the `update` call completes.
    public func confirm() async -> EmbeddedPaymentElementResult {
        guard let embeddedPaymentElement = embeddedPaymentElement else {
            return .failed(error: EmbeddedPaymentElementError.notLoaded)
        }
        
        let result = await embeddedPaymentElement.confirm()
        self.confirmationResult = result
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

/// This View takes an `EmbeddedPaymentElementViewModel` and creates an instance of `EmbeddedViewRepresentable`,
/// manages its lifecycle, and displays it within your SwiftUI view hierarchy.
struct EmbeddedPaymentElementView: View {
    private let viewModel: EmbeddedPaymentElementViewModel
    @State private var height: CGFloat = 0
    
    public init(viewModel: EmbeddedPaymentElementViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EmbeddedViewRepresentable(viewModel: viewModel, height: $height)
            .frame(height: height)
    }
}

// MARK: Internal

struct EmbeddedViewRepresentable: UIViewRepresentable {
    let viewModel: EmbeddedPaymentElementViewModel
    @Binding var height: CGFloat
    
    @State private var isFirstLayout = true
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        guard let embeddedPaymentElement = viewModel.embeddedPaymentElement else { return containerView }
        
        embeddedPaymentElement.delegate = context.coordinator
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

    func updateHeight(_ uiView: UIView) {
        DispatchQueue.main.async {
            let newHeight = uiView.systemLayoutSizeFitting(CGSize(width: uiView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
            if self.isFirstLayout {
                // No animation for the first layout
                self.height = newHeight
                self.isFirstLayout = false
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.height = newHeight
                }
            }
        }
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        // Update the presenting view controller in case it has changed
        viewModel.embeddedPaymentElement?.presentingViewController = context.coordinator.topMostViewController()

        updateHeight(uiView)
    }

    public class Coordinator: NSObject, EmbeddedPaymentElementDelegate {
        var parent: EmbeddedViewRepresentable
        
        init(_ parent: EmbeddedViewRepresentable) {
            self.parent = parent
            STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: EmbeddedSwiftUIProduct.self)
        }

        public func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
            self.parent.updateHeight(embeddedPaymentElement.view)
        }

        public func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: EmbeddedPaymentElement) {
            self.parent.viewModel.paymentOption = embeddedPaymentElement.paymentOption
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
