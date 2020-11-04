//
//  STPPaymentOptionsViewController.swift
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

/// This view controller presents a list of payment method options to the user,
/// which they can select between. They can also add credit cards to the list.
/// It must be displayed inside a `UINavigationController`, so you can either
/// create a `UINavigationController` with an `STPPaymentOptionsViewController`
/// as the `rootViewController` and then present the `UINavigationController`,
/// or push a new `STPPaymentOptionsViewController` onto an existing
/// `UINavigationController`'s stack. You can also have `STPPaymentContext` do this
/// for you automatically, by calling `presentPaymentOptionsViewController`
/// or `pushPaymentOptionsViewController` on it.
public class STPPaymentOptionsViewController: STPCoreViewController,
  STPPaymentOptionsInternalViewControllerDelegate, STPAddCardViewControllerDelegate
{

  /// The delegate for the view controller.
  /// The delegate receives callbacks when the user selects a method or cancels,
  /// and is responsible for dismissing the payments methods view controller when
  /// it is finished.
  @objc private(set) weak var delegate: STPPaymentOptionsViewControllerDelegate?

  /// Creates a new payment methods view controller.
  /// - Parameter paymentContext: A payment context to power the view controller's view.
  /// The payment context will in turn use its backend API adapter to fetch the
  /// information it needs from your application.
  /// - Returns: an initialized view controller.
  @objc(initWithPaymentContext:)
  public convenience init(paymentContext: STPPaymentContext) {
    self.init(
      configuration: paymentContext.configuration,
      apiAdapter: paymentContext.apiAdapter,
      apiClient: paymentContext.apiClient,
      loadingPromise: paymentContext.currentValuePromise,
      theme: paymentContext.theme,
      shippingAddress: paymentContext.shippingAddress,
      delegate: paymentContext)
  }

  init(
    configuration: STPPaymentConfiguration?,
    apiAdapter: STPBackendAPIAdapter?,
    apiClient: STPAPIClient?,
    loadingPromise: STPPromise<STPPaymentOptionTuple>?,
    theme: STPTheme?,
    shippingAddress: STPAddress?,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) {
    super.init(theme: theme)
    commonInit(
      configuration: configuration, apiAdapter: apiAdapter, apiClient: apiClient,
      loadingPromise: loadingPromise, shippingAddress: shippingAddress, delegate: delegate)
  }

  func commonInit(
    configuration: STPPaymentConfiguration?,
    apiAdapter: STPBackendAPIAdapter?,
    apiClient: STPAPIClient?,
    loadingPromise: STPPromise<STPPaymentOptionTuple>?,
    shippingAddress: STPAddress?,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) {
    STPAnalyticsClient.sharedClient.addClass(
      toProductUsageIfNecessary: STPPaymentOptionsViewController.self)

    self.configuration = configuration
    self.apiClient = apiClient ?? .shared
    self.shippingAddress = shippingAddress
    self.apiAdapter = apiAdapter
    self.loadingPromise = loadingPromise
    self.delegate = delegate

    navigationItem.title = STPLocalizedString(
      "Loading…", "Title for screen when data is still loading from the network.")

    weak var weakSelf = self
    loadingPromise?.onSuccess({ tuple in
      guard let strongSelf = weakSelf else {
        return
      }
      var `internal`: UIViewController?
      if (tuple.paymentOptions.count) > 0 {
        let customerContext = strongSelf.apiAdapter as? STPCustomerContext

        var payMethodsInternal: STPPaymentOptionsInternalViewController?
        if let configuration1 = strongSelf.configuration {
          payMethodsInternal = STPPaymentOptionsInternalViewController(
            configuration: configuration1,
            customerContext: customerContext,
            apiClient: strongSelf.apiClient,
            theme: strongSelf.theme,
            prefilledInformation: strongSelf.prefilledInformation,
            shippingAddress: strongSelf.shippingAddress,
            paymentOptionTuple: tuple,
            delegate: strongSelf)
        }
        if strongSelf.paymentOptionsViewControllerFooterView != nil {
          payMethodsInternal?.customFooterView = strongSelf.paymentOptionsViewControllerFooterView
        }
        if strongSelf.addCardViewControllerFooterView != nil {
          payMethodsInternal?.addCardViewControllerCustomFooterView =
            strongSelf.addCardViewControllerFooterView
        }
        `internal` = payMethodsInternal
      } else {
        var addCardViewController: STPAddCardViewController?
        if let configuration1 = strongSelf.configuration {
          addCardViewController = STPAddCardViewController(
            configuration: configuration1, theme: strongSelf.theme)
        }
        addCardViewController?.apiClient = strongSelf.apiClient
        addCardViewController?.delegate = strongSelf
        addCardViewController?.prefilledInformation = strongSelf.prefilledInformation
        addCardViewController?.shippingAddress = strongSelf.shippingAddress
        `internal` = addCardViewController

        if strongSelf.addCardViewControllerFooterView != nil {
          addCardViewController?.customFooterView = strongSelf.addCardViewControllerFooterView
        }
      }

      `internal`?.stp_navigationItemProxy = strongSelf.navigationItem
      if let controller = `internal` {
        strongSelf.addChild(controller)
      }
      `internal`?.view.alpha = 0
      if let view = `internal`?.view, let activityIndicator1 = strongSelf.activityIndicator {
        strongSelf.view.insertSubview(view, belowSubview: activityIndicator1)
      }
      if let view = `internal`?.view {
        strongSelf.view.addSubview(view)
      }
      `internal`?.view.frame = strongSelf.view.bounds
      `internal`?.didMove(toParent: strongSelf)
      UIView.animate(
        withDuration: 0.2,
        animations: {
          strongSelf.activityIndicator?.alpha = 0
          `internal`?.view.alpha = 1
        }
      ) { _ in
        strongSelf.activityIndicator?.animating = false
      }
      strongSelf.navigationItem.setRightBarButton(
        `internal`?.stp_navigationItemProxy?.rightBarButtonItem, animated: true)
      strongSelf.internalViewController = `internal`
    })
  }

  /// Initializes a new payment methods view controller without using a
  /// payment context.
  /// - Parameters:
  ///   - configuration:   The configuration to use to determine what types of
  /// payment method to offer your user. - seealso: STPPaymentConfiguration.h
  ///   - theme:           The theme to inform the appearance of the UI.
  ///   - customerContext: The customer context the view controller will use to
  /// fetch and modify its Stripe customer
  ///   - delegate:         A delegate that will be notified when the payment
  /// methods view controller's selection changes.
  /// - Returns: an initialized view controller.
  @objc(initWithConfiguration:theme:customerContext:delegate:)
  public convenience init(
    configuration: STPPaymentConfiguration,
    theme: STPTheme,
    customerContext: STPCustomerContext,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) {
    self.init(
      configuration: configuration, theme: theme, apiAdapter: customerContext, delegate: delegate)
  }

  /// Note: Instead of providing your own backend API adapter, we recommend using
  /// `STPCustomerContext`, which will manage retrieving and updating a
  /// Stripe customer for you. - seealso: STPCustomerContext.h
  /// Initializes a new payment methods view controller without using
  /// a payment context.
  /// - Parameters:
  ///   - configuration: The configuration to use to determine what types of
  /// payment method to offer your user.
  ///   - theme:         The theme to inform the appearance of the UI.
  ///   - apiAdapter:    The API adapter to use to retrieve a customer's stored
  /// payment methods and save new ones.
  ///   - delegate:      A delegate that will be notified when the payment methods
  /// view controller's selection changes.
  @objc(initWithConfiguration:theme:apiAdapter:delegate:)
  public init(
    configuration: STPPaymentConfiguration,
    theme: STPTheme,
    apiAdapter: STPBackendAPIAdapter,
    delegate: STPPaymentOptionsViewControllerDelegate
  ) {
    super.init(theme: theme)
    let promise = retrievePaymentMethods(with: configuration, apiAdapter: apiAdapter)

    commonInit(
      configuration: configuration, apiAdapter: apiAdapter, apiClient: STPAPIClient.shared,
      loadingPromise: promise, shippingAddress: nil, delegate: delegate)
  }

  /// If you've already collected some information from your user, you can set it
  /// here and it'll be automatically filled out when possible/appropriate in any UI
  /// that the payment context creates.
  @objc public var prefilledInformation: STPUserInformation?
  /// @note This is no longer recommended as of v18.3.0 - the SDK automatically saves the Stripe ID of the last selected
  /// payment method using NSUserDefaults and displays it as the default pre-selected option.  You can override this behavior
  /// by setting this property.
  /// The Stripe ID of a payment method to display as the default pre-selected option.
  /// @note Setting this after the view controller's view has loaded has no effect.
  @objc public var defaultPaymentMethod: String?
  /// A view that will be placed as the footer of the view controller when it is
  /// showing a list of saved payment methods to select from.
  /// When the footer view needs to be resized, it will be sent a
  /// `sizeThatFits:` call. The view should respond correctly to this method in order
  /// to be sized and positioned properly.
  @objc public var paymentOptionsViewControllerFooterView: UIView?
  /// A view that will be placed as the footer of the view controller when it is
  /// showing the add card view.
  /// When the footer view needs to be resized, it will be sent a
  /// `sizeThatFits:` call. The view should respond correctly to this method in order
  /// to be sized and positioned properly.
  @objc public var addCardViewControllerFooterView: UIView?
  /// The API Client to use to make requests.
  /// Defaults to STPAPIClient.shared
  @objc public var apiClient: STPAPIClient = .shared

  /// If you're pushing `STPPaymentOptionsViewController` onto an existing
  /// `UINavigationController`'s stack, you should use this method to dismiss it,
  /// since it may have pushed an additional add card view controller onto the
  /// navigation controller's stack.
  /// - Parameter completion: The callback to run after the view controller is dismissed.
  /// You may specify nil for this parameter.
  @objc(dismissWithCompletion:)
  public func dismiss(withCompletion completion: STPVoidBlock?) {
    if stp_isAtRootOfNavigationController() {
      presentingViewController?.dismiss(animated: true, completion: completion)
    } else {
      var previous = navigationController?.viewControllers.first
      for viewController in navigationController?.viewControllers ?? [] {
        if viewController == self {
          break
        }
        previous = viewController
      }
      navigationController?.stp_pop(to: previous, animated: true, completion: completion ?? {})
    }
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  @objc public required init(theme: STPTheme?) {
    super.init(theme: theme)
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  @objc public required init(
    nibName nibNameOrNil: String?,
    bundle nibBundleOrNil: Bundle?
  ) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  /// Use one of the initializers declared in this interface.
  @available(*, unavailable, message: "Use one of the initializers declared in this interface instead.")
  @objc public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  private var configuration: STPPaymentConfiguration?
  private var shippingAddress: STPAddress?
  private weak var apiAdapter: STPBackendAPIAdapter?
  var loadingPromise: STPPromise<STPPaymentOptionTuple>?
  private weak var activityIndicator: STPPaymentActivityIndicatorView?
  internal weak var internalViewController: UIViewController?

  func retrievePaymentMethods(
    with configuration: STPPaymentConfiguration,
    apiAdapter: STPBackendAPIAdapter?
  ) -> STPPromise<STPPaymentOptionTuple> {
    let promise = STPPromise<STPPaymentOptionTuple>()
    apiAdapter?.listPaymentMethodsForCustomer(completion: { paymentMethods, error in
      // We don't use stpDispatchToMainThreadIfNecessary here because we want this completion block to always be called asynchronously, so that users can set self.defaultPaymentMethod in time.
      DispatchQueue.main.async(execute: {
        if let error = error {
          promise.fail(error)
        } else {
          let defaultPaymentMethod = self.defaultPaymentMethod
          if defaultPaymentMethod == nil && (apiAdapter is STPCustomerContext) {
            // Retrieve the last selected payment method saved by STPCustomerContext
            (apiAdapter as? STPCustomerContext)?.retrieveLastSelectedPaymentMethodIDForCustomer(
              completion: { paymentMethodID, `_` in
                var paymentTuple: STPPaymentOptionTuple?
                if let paymentMethods = paymentMethods {
                  paymentTuple = STPPaymentOptionTuple.init(
                    filteredForUIWith: paymentMethods, selectedPaymentMethod: paymentMethodID,
                    configuration: configuration)
                }
                promise.succeed(paymentTuple!)
              })
          }
          var paymentTuple: STPPaymentOptionTuple?
          if let paymentMethods = paymentMethods {
            paymentTuple = STPPaymentOptionTuple.init(
              filteredForUIWith: paymentMethods, selectedPaymentMethod: defaultPaymentMethod,
              configuration: configuration)
          }
          promise.succeed(paymentTuple!)
        }
      })
    })
    return promise
  }

  override func createAndSetupViews() {
    super.createAndSetupViews()

    let activityIndicator = STPPaymentActivityIndicatorView()
    activityIndicator.animating = true
    view.addSubview(activityIndicator)
    self.activityIndicator = activityIndicator
  }

  /// :nodoc:
  @objc
  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let centerX = (view.frame.size.width - (activityIndicator?.frame.size.width ?? 0.0)) / 2
    let centerY = (view.frame.size.height - (activityIndicator?.frame.size.height ?? 0.0)) / 2
    activityIndicator?.frame = CGRect(
      x: centerX, y: centerY, width: activityIndicator?.frame.size.width ?? 0.0,
      height: activityIndicator?.frame.size.height ?? 0.0)
    internalViewController?.view.frame = view.bounds
  }

  /// :nodoc:
  @objc
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    weak var weakSelf = self
    loadingPromise?.onSuccess({ tuple in
      let strongSelf = weakSelf
      if strongSelf == nil {
        return
      }

      if tuple.selectedPaymentOption != nil {
        if strongSelf?.delegate?.responds(
          to: #selector(
            STPPaymentOptionsViewControllerDelegate.paymentOptionsViewController(_:didSelect:)))
          ?? false
        {
          if let strongSelf = strongSelf, let selectedPaymentOption = tuple.selectedPaymentOption {
            strongSelf.delegate?.paymentOptionsViewController?(
              strongSelf,
              didSelect: selectedPaymentOption)
          }
        }
      }
    }).onFailure({ error in
      let strongSelf = weakSelf
      if strongSelf == nil {
        return
      }

      if let strongSelf = strongSelf {
        strongSelf.delegate?.paymentOptionsViewController(strongSelf, didFailToLoadWithError: error)
      }
    })
  }

  @objc override func updateAppearance() {
    super.updateAppearance()

    activityIndicator?.tintColor = theme.accentColor
  }

  func finish(with paymentOption: STPPaymentOption?) {
    let isReusablePaymentMethod =
      (paymentOption is STPPaymentMethod)
      && (paymentOption as? STPPaymentMethod)?.isReusable ?? false

    if apiAdapter is STPCustomerContext {
      if isReusablePaymentMethod {
        // Save the payment method
        let paymentMethod = paymentOption as? STPPaymentMethod
        (apiAdapter as? STPCustomerContext)?.saveLastSelectedPaymentMethodID(
          forCustomer: paymentMethod?.stripeId ?? "", completion: nil)
      } else {
        // The customer selected something else (like Apple Pay)
        (apiAdapter as? STPCustomerContext)?.saveLastSelectedPaymentMethodID(
          forCustomer: nil, completion: nil)
      }
    }

    if delegate?.responds(
      to: #selector(
        STPPaymentOptionsViewControllerDelegate.paymentOptionsViewController(_:didSelect:)))
      ?? false
    {
      if let paymentOption = paymentOption {
        delegate?.paymentOptionsViewController?(self, didSelect: paymentOption)
      }
    }
    delegate?.paymentOptionsViewControllerDidFinish(self)
  }

  func internalViewControllerDidSelect(_ paymentOption: STPPaymentOption?) {
    finish(with: paymentOption)
  }

  func internalViewControllerDidDelete(_ paymentOption: STPPaymentOption?) {
    if delegate is STPPaymentContext {
      // Notify payment context to update its copy of payment methods
      if let paymentContext = delegate as? STPPaymentContext, let paymentOption = paymentOption {
        paymentContext.remove(paymentOption)
      }
    }
  }

  func internalViewControllerDidCreatePaymentOption(
    _ paymentOption: STPPaymentOption?, completion: @escaping STPErrorBlock
  ) {
    if !(paymentOption?.isReusable ?? false) {
      // Don't save a non-reusable payment option
      finish(with: paymentOption)
      return
    }
    let paymentMethod = paymentOption as? STPPaymentMethod
    if let paymentMethod = paymentMethod {
      apiAdapter?.attachPaymentMethod(toCustomer: paymentMethod) { error in
        stpDispatchToMainThreadIfNecessary({
          completion(error)
          if error == nil {
            var promise: STPPromise<STPPaymentOptionTuple>?
            if let configuration = self.configuration {
              promise = self.retrievePaymentMethods(
                with: configuration, apiAdapter: self.apiAdapter)
            }
            weak var weakSelf = self
            promise?.onSuccess({ tuple in
              let strongSelf = weakSelf
              if strongSelf == nil {
                return
              }
              let paymentTuple = STPPaymentOptionTuple(
                paymentOptions: tuple.paymentOptions, selectedPaymentOption: paymentMethod)
              if strongSelf?.internalViewController is STPPaymentOptionsInternalViewController {
                let paymentOptionsVC =
                  strongSelf?.internalViewController as? STPPaymentOptionsInternalViewController
                paymentOptionsVC?.update(with: paymentTuple)
              }
            })
            self.finish(with: paymentMethod)
          }
        })
      }
    }
  }

  func internalViewControllerDidCancel() {
    delegate?.paymentOptionsViewControllerDidCancel(self)
  }

  @objc override func handleCancelTapped(_ sender: Any?) {
    delegate?.paymentOptionsViewControllerDidCancel(self)
  }

  @objc
  public func addCardViewControllerDidCancel(
    _ addCardViewController: STPAddCardViewController
  ) {
    // Add card is only our direct delegate if there are no other payment methods possible
    // and we skipped directly to this screen. In this case, a cancel from it is the same as a cancel to us.
    delegate?.paymentOptionsViewControllerDidCancel(self)
  }

  @objc
  public func addCardViewController(
    _ addCardViewController: STPAddCardViewController,
    didCreatePaymentMethod paymentMethod: STPPaymentMethod,
    completion: @escaping STPErrorBlock
  ) {
    internalViewControllerDidCreatePaymentOption(paymentMethod, completion: completion)
  }
}

// MARK: - STPPaymentOptionsViewControllerDelegate

/// An `STPPaymentOptionsViewControllerDelegate` responds when a user selects a
/// payment option from (or cancels) an `STPPaymentOptionsViewController`. In both
/// of these instances, you should dismiss the view controller (either by popping
/// it off the navigation stack, or dismissing it).
@objc public protocol STPPaymentOptionsViewControllerDelegate: NSObjectProtocol {
  /// This is called when the view controller encounters an error fetching the user's
  /// payment options from its API adapter. You should dismiss the view controller
  /// when this is called.
  /// - Parameters:
  ///   - paymentOptionsViewController: the view controller in question
  ///   - error:                        the error that occurred
  func paymentOptionsViewController(
    _ paymentOptionsViewController: STPPaymentOptionsViewController,
    didFailToLoadWithError error: Error
  )
  /// This is called when the user selects or adds a payment method, so it will often
  /// be called immediately after calling `paymentOptionsViewController:didSelectPaymentOption:`.
  /// You should dismiss the view controller when this is called.
  /// - Parameter paymentOptionsViewController: the view controller that has finished
  func paymentOptionsViewControllerDidFinish(
    _ paymentOptionsViewController: STPPaymentOptionsViewController)
  /// This is called when the user taps "cancel".
  /// You should dismiss the view controller when this is called.
  /// - Parameter paymentOptionsViewController: the view controller that has finished
  func paymentOptionsViewControllerDidCancel(
    _ paymentOptionsViewController: STPPaymentOptionsViewController)

  /// This is called when the user either makes a selection, or adds a new card.
  /// This will be triggered after the view controller loads with the user's current
  /// selection (if they have one) and then subsequently when they change their
  /// choice. You should use this callback to update any necessary UI in your app
  /// that displays the user's currently selected payment method. You should *not*
  /// dismiss the view controller at this point, instead do this in
  /// `paymentOptionsViewControllerDidFinish:`. `STPPaymentOptionsViewController`
  /// will also call the necessary methods on your API adapter, so you don't need to
  /// call them directly during this method.
  /// - Parameters:
  ///   - paymentOptionsViewController: the view controller in question
  ///   - paymentOption:                the selected payment method
  @objc(paymentOptionsViewController:didSelectPaymentOption:)
  optional func paymentOptionsViewController(
    _ paymentOptionsViewController: STPPaymentOptionsViewController,
    didSelect paymentOption: STPPaymentOption
  )
}
