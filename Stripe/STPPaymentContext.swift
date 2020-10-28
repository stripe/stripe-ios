//
//  STPPaymentContext.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation
import ObjectiveC
import PassKit

/// An `STPPaymentContext` keeps track of all of the state around a payment. It will manage fetching a user's saved payment methods, tracking any information they select, and prompting them for required additional information before completing their purchase. It can be used to power your application's "payment confirmation" page with just a few lines of code.
/// `STPPaymentContext` also provides a unified interface to multiple payment methods - for example, you can write a single integration to accept both credit card payments and Apple Pay.
/// `STPPaymentContext` saves information about a user's payment methods to a Stripe customer object, and requires an `STPCustomerContext` to manage retrieving and modifying the customer.
public class STPPaymentContext: NSObject, STPAuthenticationContext,
  STPPaymentOptionsViewControllerDelegate, STPShippingAddressViewControllerDelegate
{
  /// This is a convenience initializer; it is equivalent to calling
  /// `init(customerContext:customerContext
  /// configuration:STPPaymentConfiguration.shared
  /// theme:STPTheme.defaultTheme`.
  /// - Parameter customerContext:  The customer context the payment context will use to fetch
  /// and modify its Stripe customer. - seealso: STPCustomerContext.h
  /// - Returns: the newly-instantiated payment context
  @objc
  public convenience init(customerContext: STPCustomerContext) {
    self.init(apiAdapter: customerContext)
  }

  /// Initializes a new Payment Context with the provided customer context, configuration,
  /// and theme. After this class is initialized, you should also make sure to set its
  /// `delegate` and `hostViewController` properties.
  /// - Parameters:
  ///   - customerContext:   The customer context the payment context will use to fetch
  /// and modify its Stripe customer. - seealso: STPCustomerContext.h
  ///   - configuration:     The configuration for the payment context to use. This
  /// lets you set your Stripe publishable API key, required billing address fields, etc.
  /// - seealso: STPPaymentConfiguration.h
  ///   - theme:             The theme describing the visual appearance of all UI
  /// that the payment context automatically creates for you. - seealso: STPTheme.h
  /// - Returns: the newly-instantiated payment context
  @objc
  public convenience init(
    customerContext: STPCustomerContext,
    configuration: STPPaymentConfiguration,
    theme: STPTheme
  ) {
    self.init(
      apiAdapter: customerContext,
      configuration: configuration,
      theme: theme)
  }

  /// Note: Instead of providing your own backend API adapter, we recommend using
  /// `STPCustomerContext`, which will manage retrieving and updating a
  /// Stripe customer for you. - seealso: STPCustomerContext.h
  /// This is a convenience initializer; it is equivalent to calling
  /// `init(apiAdapter:apiAdapter configuration:STPPaymentConfiguration.shared theme:STPTheme.defaultTheme)`.
  @objc
  public convenience init(apiAdapter: STPBackendAPIAdapter) {
    self.init(
      apiAdapter: apiAdapter,
      configuration: STPPaymentConfiguration.shared,
      theme: STPTheme.defaultTheme)
  }

  /// Note: Instead of providing your own backend API adapter, we recommend using
  /// `STPCustomerContext`, which will manage retrieving and updating a
  /// Stripe customer for you. - seealso: STPCustomerContext.h
  /// Initializes a new Payment Context with the provided API adapter and configuration.
  /// After this class is initialized, you should also make sure to set its `delegate`
  /// and `hostViewController` properties.
  /// - Parameters:
  ///   - apiAdapter:    The API adapter the payment context will use to fetch and
  /// modify its contents. You need to make a class conforming to this protocol that
  /// talks to your server. - seealso: STPBackendAPIAdapter.h
  ///   - configuration: The configuration for the payment context to use. This lets
  /// you set your Stripe publishable API key, required billing address fields, etc.
  /// - seealso: STPPaymentConfiguration.h
  ///   - theme:         The theme describing the visual appearance of all UI that
  /// the payment context automatically creates for you. - seealso: STPTheme.h
  /// - Returns: the newly-instantiated payment context
  @objc
  public init(
    apiAdapter: STPBackendAPIAdapter,
    configuration: STPPaymentConfiguration,
    theme: STPTheme
  ) {
    STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPPaymentContext.self)
    self.configuration = configuration
    self.apiAdapter = apiAdapter
    self.theme = theme
    paymentCurrency = "USD"
    paymentCountry = "US"
    apiClient = STPAPIClient.shared
    modalPresentationStyle = .fullScreen
    state = STPPaymentContextState.none
    super.init()
    retryLoading()
  }

  /// Note: Instead of providing your own backend API adapter, we recommend using
  /// `STPCustomerContext`, which will manage retrieving and updating a
  /// Stripe customer for you. - seealso: STPCustomerContext.h
  /// The API adapter the payment context will use to fetch and modify its contents.
  /// You need to make a class conforming to this protocol that talks to your server.
  /// - seealso: STPBackendAPIAdapter.h
  @objc public private(set) var apiAdapter: STPBackendAPIAdapter
  /// The configuration for the payment context to use internally. - seealso: STPPaymentConfiguration.h
  @objc public private(set) var configuration: STPPaymentConfiguration
  /// The visual appearance that will be used by any views that the context generates. - seealso: STPTheme.h
  @objc public private(set) var theme: STPTheme

  private var _prefilledInformation: STPUserInformation?
  /// If you've already collected some information from your user, you can set it here and it'll be automatically filled out when possible/appropriate in any UI that the payment context creates.
  @objc public var prefilledInformation: STPUserInformation? {
    get {
      _prefilledInformation
    }
    set(prefilledInformation) {
      _prefilledInformation = prefilledInformation
      if prefilledInformation?.shippingAddress != nil && shippingAddress == nil {
        shippingAddress = prefilledInformation?.shippingAddress
        shippingAddressNeedsVerification = true
      }
    }
  }

  private weak var _hostViewController: UIViewController?
  /// The view controller that any additional UI will be presented on. If you have a "checkout view controller" in your app, that should be used as the host view controller.
  @objc public weak var hostViewController: UIViewController? {
    get {
      _hostViewController
    }
    set(hostViewController) {
      assert(
        _hostViewController == nil,
        "You cannot change the hostViewController on an STPPaymentContext after it's already been set."
      )
      _hostViewController = hostViewController
      if hostViewController is UINavigationController {
        originalTopViewController =
          (hostViewController as? UINavigationController)?.topViewController
      }
      if let hostViewController = hostViewController {
        artificiallyRetain(hostViewController)
      }
    }
  }

  private weak var _delegate: STPPaymentContextDelegate?
  /// This delegate will be notified when the payment context's contents change. - seealso: STPPaymentContextDelegate
  @objc public weak var delegate: STPPaymentContextDelegate? {
    get {
      _delegate
    }
    set(delegate) {
      _delegate = delegate
      DispatchQueue.main.async(execute: {
        self.delegate?.paymentContextDidChange(self)
      })
    }
  }
  /// Whether or not the payment context is currently loading information from the network.

  @objc public var loading: Bool {
    return !(loadingPromise?.completed)!
  }
  /// @note This is no longer recommended as of v18.3.0 - the SDK automatically saves the Stripe ID of the last selected
  /// payment method using NSUserDefaults and displays it as the default pre-selected option.  You can override this behavior
  /// by setting this property.
  /// The Stripe ID of a payment method to display as the default pre-selected option.
  /// @note Set this property immediately after initializing STPPaymentContext, or call `retryLoading` afterwards.
  @objc public var defaultPaymentMethod: String?

  private var _selectedPaymentOption: STPPaymentOption?
  /// The user's currently selected payment option. May be nil.
  @objc public private(set) var selectedPaymentOption: STPPaymentOption? {
    get {
      _selectedPaymentOption
    }
    set {
      if let newValue = newValue, let paymentOptions = self.paymentOptions {
        if !paymentOptions.contains(where: { (option) -> Bool in
          newValue.isEqual(option)
        }) {
          if newValue.isReusable {
            self.paymentOptions = paymentOptions + [newValue]
          }
        }
      }
      if !(_selectedPaymentOption?.isEqual(newValue) ?? false) {
        _selectedPaymentOption = newValue
        stpDispatchToMainThreadIfNecessary({
          self.delegate?.paymentContextDidChange(self)
        })
      }

    }
  }

  private var _paymentOptions: [STPPaymentOption]?
  /// The available payment options the user can choose between. May be nil.
  @objc public private(set) var paymentOptions: [STPPaymentOption]? {
    get {
      _paymentOptions
    }
    set {
      _paymentOptions = newValue?.sorted(by: { (obj1, obj2) -> Bool in
        let applePayKlass = STPApplePayPaymentOption.self
        let paymentMethodKlass = STPPaymentMethod.self
        if obj1.isKind(of: applePayKlass) {
          return true
        } else if obj2.isKind(of: applePayKlass) {
          return false
        }
        if obj1.isKind(of: paymentMethodKlass) && obj2.isKind(of: paymentMethodKlass) {
          return (obj1.label.compare(obj2.label) == .orderedAscending)
        }
        return false
      })
    }
  }

  /// The user's currently selected shipping method. May be nil.
  @objc public internal(set) var selectedShippingMethod: PKShippingMethod?

  private var _shippingMethods: [PKShippingMethod]?
  /// An array of STPShippingMethod objects that describe the supported shipping methods. May be nil.
  @objc public private(set) var shippingMethods: [PKShippingMethod]? {
    get {
      _shippingMethods
    }
    set {
      _shippingMethods = newValue
      if let shippingMethods = newValue, let selectedShippingMethod = self.selectedShippingMethod {
        if shippingMethods.count == 0 {
          self.selectedShippingMethod = nil
        } else if shippingMethods.contains(selectedShippingMethod) {
          self.selectedShippingMethod = shippingMethods.first
        }
      }
    }
  }

  /// The user's shipping address. May be nil.
  /// If you've already collected a shipping address from your user, you may
  /// prefill it by setting a shippingAddress in PaymentContext's prefilledInformation.
  /// When your user enters a new shipping address, PaymentContext will save it to
  /// the current customer object. When PaymentContext loads, if you haven't
  /// manually set a prefilled value, any shipping information saved on the customer
  /// will be used to prefill the shipping address form. Note that because your
  /// customer's email may not be the same as the email provided with their shipping
  /// info, PaymentContext will not prefill the shipping form's email using your
  /// customer's email.
  /// You should not rely on the shipping information stored on the Stripe customer
  /// for order fulfillment, as your user may change this information if they make
  /// multiple purchases. We recommend adding shipping information when you create
  /// a charge (which can also help prevent fraud), or saving it to your own
  /// database. https://stripe.com/docs/api/payment_intents/create#create_payment_intent-shipping
  /// Note: by default, your user will still be prompted to verify a prefilled
  /// shipping address. To change this behavior, you can set
  /// `verifyPrefilledShippingAddress` to NO in your `STPPaymentConfiguration`.
  @objc public private(set) var shippingAddress: STPAddress?
  /// The amount of money you're requesting from the user, in the smallest currency
  /// unit for the selected currency. For example, to indicate $10 USD, use 1000
  /// (i.e. 1000 cents). For more information, see https://stripe.com/docs/api/payment_intents/create#create_payment_intent-amount
  /// @note This value must be present and greater than zero in order for Apple Pay
  /// to be automatically enabled.
  /// @note You should only set either this or `paymentSummaryItems`, not both.
  /// The other will be automatically calculated on demand using your `paymentCurrency`.

  @objc public var paymentAmount: Int {
    get {
      return paymentAmountModel.paymentAmount(
        withCurrency: paymentCurrency,
        shippingMethod: selectedShippingMethod)
    }
    set(paymentAmount) {
      paymentAmountModel = STPPaymentContextAmountModel(amount: paymentAmount)
    }
  }
  /// The three-letter currency code for the currency of the payment (i.e. USD, GBP,
  /// JPY, etc). Defaults to "USD".
  /// @note Changing this property may change the return value of `paymentAmount`
  /// or `paymentSummaryItems` (whichever one you didn't directly set yourself).
  @objc public var paymentCurrency: String
  /// The two-letter country code for the country where the payment will be processed.
  /// You should set this to the country your Stripe account is in. Defaults to "US".
  /// @note Changing this property will change the `countryCode` of your Apple Pay
  /// payment requests.
  /// - seealso: PKPaymentRequest for more information.
  @objc public var paymentCountry: String
  /// If you support Apple Pay, you can optionally set the PKPaymentSummaryItems
  /// you want to display here instead of using `paymentAmount`. Note that the
  /// grand total (the amount of the last summary item) must be greater than zero.
  /// If not set, a single summary item will be automatically generated using
  /// `paymentAmount` and your configuration's `companyName`.
  /// - seealso: PKPaymentRequest for more information
  /// @note You should only set either this or `paymentAmount`, not both.
  /// The other will be automatically calculated on demand using your `paymentCurrency.`

  @objc public var paymentSummaryItems: [PKPaymentSummaryItem] {
    get {
      return paymentAmountModel.paymentSummaryItems(
        withCurrency: paymentCurrency,
        companyName: configuration.companyName,
        shippingMethod: selectedShippingMethod) ?? []
    }
    set(paymentSummaryItems) {
      paymentAmountModel = STPPaymentContextAmountModel(paymentSummaryItems: paymentSummaryItems)
    }
  }
  /// The presentation style used for all view controllers presented modally by the context.
  /// Since custom transition styles are not supported, you should set this to either
  /// `UIModalPresentationFullScreen`, `UIModalPresentationPageSheet`, or `UIModalPresentationFormSheet`.
  /// The default value is `UIModalPresentationFullScreen`.
  @objc public var modalPresentationStyle: UIModalPresentationStyle = .fullScreen
  /// The mode to use when displaying the title of the navigation bar in all view
  /// controllers presented by the context. The default value is `automatic`,
  /// which causes the title to use the same styling as the previously displayed
  /// navigation item (if the view controller is pushed onto the `hostViewController`).
  /// If the `prefersLargeTitles` property of the `hostViewController`'s navigation bar
  /// is false, this property has no effect and the navigation item's title is always
  /// displayed as a small title.
  /// If the view controller is presented modally, `automatic` and
  /// `never` always result in a navigation bar with a small title.
  @objc public var largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.automatic
  /// A view that will be placed as the footer of the payment options selection
  /// view controller.
  /// When the footer view needs to be resized, it will be sent a
  /// `sizeThatFits:` call. The view should respond correctly to this method in order
  /// to be sized and positioned properly.
  @objc public var paymentOptionsViewControllerFooterView: UIView?
  /// A view that will be placed as the footer of the add card view controller.
  /// When the footer view needs to be resized, it will be sent a
  /// `sizeThatFits:` call. The view should respond correctly to this method in order
  /// to be sized and positioned properly.
  @objc public var addCardViewControllerFooterView: UIView?
  /// The API Client to use to make requests.
  /// Defaults to STPAPIClient.shared
  @objc public var apiClient: STPAPIClient = .shared

  /// If `paymentContext:didFailToLoadWithError:` is called on your delegate, you
  /// can in turn call this method to try loading again (if that hasn't been called,
  /// calling this will do nothing). If retrying in turn fails, `paymentContext:didFailToLoadWithError:`
  /// will be called again (and you can again call this to keep retrying, etc).
  @objc
  public func retryLoading() {
    // Clear any cached customer object and attached payment methods before refetching
    if apiAdapter is STPCustomerContext {
      let customerContext = apiAdapter as? STPCustomerContext
      customerContext?.clearCache()
    }
    weak var weakSelf = self
    loadingPromise = STPPromise<STPPaymentOptionTuple>.init().onSuccess({ tuple in
      guard let strongSelf = weakSelf else {
        return
      }
      strongSelf.paymentOptions = tuple.paymentOptions
      strongSelf.selectedPaymentOption = tuple.selectedPaymentOption
    }).onFailure({ error in
      guard let strongSelf = weakSelf else {
        return
      }
      if strongSelf.hostViewController != nil {
        if strongSelf.paymentOptionsViewController != nil
          && strongSelf.paymentOptionsViewController?.viewIfLoaded?.window != nil
        {
          if let paymentOptionsViewController1 = strongSelf.paymentOptionsViewController {
            strongSelf.appropriatelyDismiss(paymentOptionsViewController1) {
              strongSelf.delegate?.paymentContext(strongSelf, didFailToLoadWithError: error)
            }
          }
        } else {
          strongSelf.delegate?.paymentContext(strongSelf, didFailToLoadWithError: error)
        }
      }
    })
    apiAdapter.retrieveCustomer({ customer, retrieveCustomerError in
      stpDispatchToMainThreadIfNecessary({
        guard let strongSelf = weakSelf else {
          return
        }
        if let retrieveCustomerError = retrieveCustomerError {
          strongSelf.loadingPromise?.fail(retrieveCustomerError)
          return
        }
        if strongSelf.shippingAddress == nil && customer?.shippingAddress != nil {
          strongSelf.shippingAddress = customer?.shippingAddress
          strongSelf.shippingAddressNeedsVerification = true
        }

        strongSelf.apiAdapter.listPaymentMethodsForCustomer(completion: { paymentMethods, error in
          guard let strongSelf2 = weakSelf else {
            return
          }
          stpDispatchToMainThreadIfNecessary({
            if let error = error {
              strongSelf2.loadingPromise?.fail(error)
              return
            }

            if self.defaultPaymentMethod == nil && (strongSelf2.apiAdapter is STPCustomerContext) {
              // Retrieve the last selected payment method saved by STPCustomerContext
              (strongSelf2.apiAdapter as? STPCustomerContext)?
                .retrieveLastSelectedPaymentMethodIDForCustomer(completion: {
                  paymentMethodID, `_` in
                  guard let strongSelf3 = weakSelf else {
                    return
                  }
                  if let paymentMethods = paymentMethods
                  {
                    let paymentTuple = STPPaymentOptionTuple(
                      filteredForUIWith: paymentMethods, selectedPaymentMethod: paymentMethodID,
                      configuration: strongSelf3.configuration)
                    strongSelf3.loadingPromise?.succeed(paymentTuple)
                  } else {
                    strongSelf3.loadingPromise?.fail(STPErrorCode.invalidRequestError as! Error)
                  }
                })
            } else {
              if let paymentMethods = paymentMethods
              {
                let paymentTuple = STPPaymentOptionTuple(
                  filteredForUIWith: paymentMethods,
                  selectedPaymentMethod: self.defaultPaymentMethod, configuration: strongSelf2.configuration)
                strongSelf2.loadingPromise?.succeed(paymentTuple)
              }
            }
          })
        })
      })
    })
  }

  /// This creates, configures, and appropriately presents an `STPPaymentOptionsViewController`
  /// on top of the payment context's `hostViewController`. It'll be dismissed automatically
  /// when the user is done selecting their payment method.
  /// @note This method will do nothing if it is called while STPPaymentContext is
  /// already showing a view controller or in the middle of requesting a payment.
  @objc
  public func presentPaymentOptionsViewController() {
    presentPaymentOptionsViewController(withNewState: .showingRequestedViewController)
  }

  /// This creates, configures, and appropriately pushes an `STPPaymentOptionsViewController`
  /// onto the navigation stack of the context's `hostViewController`. It'll be popped
  /// automatically when the user is done selecting their payment method.
  /// @note This method will do nothing if it is called while STPPaymentContext is
  /// already showing a view controller or in the middle of requesting a payment.
  @objc
  public func pushPaymentOptionsViewController() {
    assert(
      hostViewController != nil && hostViewController?.viewIfLoaded?.window != nil,
      "hostViewController must not be nil on STPPaymentContext when calling pushPaymentOptionsViewController on it. Next time, set the hostViewController property first!"
    )
    var navigationController: UINavigationController?
    if hostViewController is UINavigationController {
      navigationController = hostViewController as? UINavigationController
    } else {
      navigationController = hostViewController?.navigationController
    }
    assert(
      navigationController != nil,
      "The payment context's hostViewController is not a navigation controller, or is not contained in one. Either make sure it is inside a navigation controller before calling pushPaymentOptionsViewController, or call presentPaymentOptionsViewController instead."
    )
    if state == STPPaymentContextState.none {
      state = .showingRequestedViewController

      let paymentOptionsViewController = STPPaymentOptionsViewController(paymentContext: self)
      self.paymentOptionsViewController = paymentOptionsViewController
      paymentOptionsViewController.prefilledInformation = prefilledInformation
      paymentOptionsViewController.defaultPaymentMethod = defaultPaymentMethod
      paymentOptionsViewController.paymentOptionsViewControllerFooterView =
        paymentOptionsViewControllerFooterView
      paymentOptionsViewController.addCardViewControllerFooterView = addCardViewControllerFooterView
      paymentOptionsViewController.navigationItem.largeTitleDisplayMode = largeTitleDisplayMode

      navigationController?.pushViewController(
        paymentOptionsViewController,
        animated: transitionAnimationsEnabled())
    }
  }

  /// This creates, configures, and appropriately presents a view controller for
  /// collecting shipping address and shipping method on top of the payment context's
  /// `hostViewController`. It'll be dismissed automatically when the user is done
  /// entering their shipping info.
  /// @note This method will do nothing if it is called while STPPaymentContext is
  /// already showing a view controller or in the middle of requesting a payment.
  @objc
  public func presentShippingViewController() {
    presentShippingViewController(withNewState: .showingRequestedViewController)
  }

  /// This creates, configures, and appropriately pushes a view controller for
  /// collecting shipping address and shipping method onto the navigation stack of
  /// the context's `hostViewController`. It'll be popped automatically when the
  /// user is done entering their shipping info.
  /// @note This method will do nothing if it is called while STPPaymentContext is
  /// already showing a view controller, or in the middle of requesting a payment.
  @objc
  public func pushShippingViewController() {
    assert(
      hostViewController != nil && hostViewController?.viewIfLoaded?.window != nil,
      "hostViewController must not be nil on STPPaymentContext when calling pushShippingViewController on it. Next time, set the hostViewController property first!"
    )
    var navigationController: UINavigationController?
    if hostViewController is UINavigationController {
      navigationController = hostViewController as? UINavigationController
    } else {
      navigationController = hostViewController?.navigationController
    }
    assert(
      navigationController != nil,
      "The payment context's hostViewController is not a navigation controller, or is not contained in one. Either make sure it is inside a navigation controller before calling pushShippingInfoViewController, or call presentShippingInfoViewController instead."
    )
    if state == STPPaymentContextState.none {
      state = .showingRequestedViewController

      let addressViewController = STPShippingAddressViewController(paymentContext: self)
      addressViewController.navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
      navigationController?.pushViewController(
        addressViewController,
        animated: transitionAnimationsEnabled())
    }
  }

  /// Requests payment from the user. This may need to present some supplemental UI
  /// to the user, in which case it will be presented on the payment context's
  /// `hostViewController`. For instance, if they've selected Apple Pay as their
  /// payment method, calling this method will show the payment sheet. If the user
  /// has a card on file, this will use that without presenting any additional UI.
  /// After this is called, the `paymentContext:didCreatePaymentResult:completion:`
  /// and `paymentContext:didFinishWithStatus:error:` methods will be called on the
  /// context's `delegate`.
  /// @note This method will do nothing if it is called while STPPaymentContext is
  /// already showing a view controller, or in the middle of requesting a payment.
  @objc
  public func requestPayment() {
    weak var weakSelf = self
    loadingPromise?.onSuccess({ _ in
      guard let strongSelf = weakSelf else {
        return
      }

      if strongSelf.state != STPPaymentContextState.none {
        return
      }

      if strongSelf.selectedPaymentOption == nil {
        strongSelf.presentPaymentOptionsViewController(withNewState: .requestingPayment)
      } else if strongSelf.requestPaymentShouldPresentShippingViewController() {
        strongSelf.presentShippingViewController(withNewState: .requestingPayment)
      } else if (strongSelf.selectedPaymentOption is STPPaymentMethod)
        || (self.selectedPaymentOption is STPPaymentMethodParams)
      {
        strongSelf.state = .requestingPayment
        let result = STPPaymentResult(paymentOption: strongSelf.selectedPaymentOption!)
        strongSelf.delegate?.paymentContext(self, didCreatePaymentResult: result) { status, error in
          stpDispatchToMainThreadIfNecessary({
            strongSelf.didFinish(with: status, error: error)
          })
        }
      } else if strongSelf.selectedPaymentOption is STPApplePayPaymentOption {
        assert(
          strongSelf.hostViewController != nil,
          "hostViewController must not be nil on STPPaymentContext. Next time, set the hostViewController property first!"
        )
        strongSelf.state = .requestingPayment
        let paymentRequest = strongSelf.buildPaymentRequest()
        let shippingAddressHandler: STPShippingAddressSelectionBlock = {
          shippingAddress, completion in
          // Apple Pay always returns a partial address here, so we won't
          // update self.shippingAddress or self.shippingMethods
          if strongSelf.delegate?.responds(
            to: #selector(
              STPPaymentContextDelegate.paymentContext(_:didUpdateShippingAddress:completion:)))
            ?? false
          {
            strongSelf.delegate?.paymentContext?(
              strongSelf, didUpdateShippingAddress: shippingAddress
            ) { status, _, shippingMethods, _ in
              completion(status, shippingMethods ?? [], strongSelf.paymentSummaryItems)
            }
          } else {
            completion(
              .valid, strongSelf.shippingMethods ?? [], strongSelf.paymentSummaryItems)
          }
        }
        let shippingMethodHandler: STPShippingMethodSelectionBlock = { shippingMethod, completion in
          strongSelf.selectedShippingMethod = shippingMethod
          strongSelf.delegate?.paymentContextDidChange(strongSelf)
          completion(self.paymentSummaryItems)
        }
        let paymentHandler: STPPaymentAuthorizationBlock = { payment in
          strongSelf.selectedShippingMethod = payment.shippingMethod
          if let shippingContact = payment.shippingContact {
            strongSelf.shippingAddress = STPAddress(pkContact: shippingContact)
          }
          strongSelf.shippingAddressNeedsVerification = false
          strongSelf.delegate?.paymentContextDidChange(strongSelf)
          if strongSelf.apiAdapter is STPCustomerContext {
            let customerContext = strongSelf.apiAdapter as? STPCustomerContext
            if let shippingAddress1 = strongSelf.shippingAddress {
              customerContext?.updateCustomer(
                withShippingAddress: shippingAddress1, completion: nil)
            }
          }
        }
        let applePayPaymentMethodHandler: STPApplePayPaymentMethodHandlerBlock = {
          paymentMethod, completion in
          strongSelf.apiAdapter.attachPaymentMethod(toCustomer: paymentMethod) {
            attachPaymentMethodError in
            stpDispatchToMainThreadIfNecessary({
              if attachPaymentMethodError != nil {
                completion(.error, attachPaymentMethodError)
              } else {
                let result = STPPaymentResult(paymentOption: paymentMethod)
                strongSelf.delegate?.paymentContext(strongSelf, didCreatePaymentResult: result) {
                  status, error in
                  // for Apple Pay, the didFinishWithStatus callback is fired later when Apple Pay VC finishes
                  completion(status, error)
                }
              }
            })
          }
        }
        if let paymentRequest = paymentRequest {
          strongSelf.applePayVC = PKPaymentAuthorizationViewController.stp_controller(
            with: paymentRequest,
            apiClient: strongSelf.apiClient,
            onShippingAddressSelection: shippingAddressHandler,
            onShippingMethodSelection: shippingMethodHandler,
            onPaymentAuthorization: paymentHandler,
            onPaymentMethodCreation: applePayPaymentMethodHandler,
            onFinish: { status, error in
              if strongSelf.applePayVC?.presentingViewController != nil {
                strongSelf.hostViewController?.dismiss(
                  animated: strongSelf.transitionAnimationsEnabled()
                ) {
                  strongSelf.didFinish(with: status, error: error)
                }
              } else {
                strongSelf.didFinish(with: status, error: error)
              }
              strongSelf.applePayVC = nil
            })
        }
        if let applePayVC1 = strongSelf.applePayVC {
          strongSelf.hostViewController?.present(
            applePayVC1,
            animated: strongSelf.transitionAnimationsEnabled())
        }
      }
    }).onFailure({ error in
      guard let strongSelf = weakSelf else {
        return
      }
      strongSelf.didFinish(with: .error, error: error)
    })
  }
  private var loadingPromise: STPPromise<STPPaymentOptionTuple>?
  private weak var paymentOptionsViewController: STPPaymentOptionsViewController?
  private var state: STPPaymentContextState = .none
  private var paymentAmountModel = STPPaymentContextAmountModel(amount: 0)
  private var shippingAddressNeedsVerification = false
  // If hostViewController was set to a nav controller, the original VC on top of the stack
  private weak var originalTopViewController: UIViewController?
  private var applePayVC: PKPaymentAuthorizationViewController?

  // Disable transition animations in tests
  func transitionAnimationsEnabled() -> Bool {
    return NSClassFromString("XCTest") == nil
  }

  var currentValuePromise: STPPromise<STPPaymentOptionTuple> {
    weak var weakSelf = self
    return
      (loadingPromise?.map({ _ in
        guard let strongSelf = weakSelf, let paymentOptions = strongSelf.paymentOptions else {
          return STPPaymentOptionTuple()
        }
        return STPPaymentOptionTuple(
          paymentOptions: paymentOptions,
          selectedPaymentOption: strongSelf.selectedPaymentOption)
      }))!
  }

  func remove(_ paymentOptionToRemove: STPPaymentOption?) {
    // Remove payment method from cached representation
    var paymentOptions = self.paymentOptions
    paymentOptions?.removeAll { $0 as AnyObject === paymentOptionToRemove as AnyObject }
    self.paymentOptions = paymentOptions

    // Elect new selected payment method if needed
    if let selectedPaymentOption = selectedPaymentOption,
      selectedPaymentOption.isEqual(paymentOptionToRemove)
    {
      self.selectedPaymentOption = self.paymentOptions?.first
    }
  }

  // MARK: - Payment Methods

  func presentPaymentOptionsViewController(withNewState state: STPPaymentContextState) {
    assert(
      hostViewController != nil && hostViewController?.viewIfLoaded?.window != nil,
      "hostViewController must not be nil on STPPaymentContext when calling pushPaymentOptionsViewController on it. Next time, set the hostViewController property first!"
    )
    if self.state == STPPaymentContextState.none {
      self.state = state
      let paymentOptionsViewController = STPPaymentOptionsViewController(paymentContext: self)
      self.paymentOptionsViewController = paymentOptionsViewController
      paymentOptionsViewController.prefilledInformation = prefilledInformation
      paymentOptionsViewController.defaultPaymentMethod = defaultPaymentMethod
      paymentOptionsViewController.paymentOptionsViewControllerFooterView =
        paymentOptionsViewControllerFooterView
      paymentOptionsViewController.addCardViewControllerFooterView = addCardViewControllerFooterView
      paymentOptionsViewController.navigationItem.largeTitleDisplayMode = largeTitleDisplayMode

      let navigationController = UINavigationController(
        rootViewController: paymentOptionsViewController)
      navigationController.navigationBar.stp_theme = theme
      navigationController.navigationBar.prefersLargeTitles = true
      navigationController.modalPresentationStyle = modalPresentationStyle
      hostViewController?.present(
        navigationController,
        animated: transitionAnimationsEnabled())
    }
  }

  @objc
  public func paymentOptionsViewController(
    _ paymentOptionsViewController: STPPaymentOptionsViewController,
    didSelect paymentOption: STPPaymentOption
  ) {
    selectedPaymentOption = paymentOption
  }

  @objc
  public func paymentOptionsViewControllerDidFinish(
    _ paymentOptionsViewController: STPPaymentOptionsViewController
  ) {
    appropriatelyDismiss(paymentOptionsViewController) {
      if self.state == .requestingPayment {
        self.state = STPPaymentContextState.none
        self.requestPayment()
      } else {
        self.state = STPPaymentContextState.none
      }
    }
  }

  @objc
  public func paymentOptionsViewControllerDidCancel(
    _ paymentOptionsViewController: STPPaymentOptionsViewController
  ) {
    appropriatelyDismiss(paymentOptionsViewController) {
      if self.state == .requestingPayment {
        self.didFinish(
          with: .userCancellation,
          error: nil)
      } else {
        self.state = STPPaymentContextState.none
      }
    }
  }

  @objc
  public func paymentOptionsViewController(
    _ paymentOptionsViewController: STPPaymentOptionsViewController,
    didFailToLoadWithError error: Error
  ) {
    // we'll handle this ourselves when the loading promise fails.
  }

  @objc(appropriatelyDismissPaymentOptionsViewController:completion:) func appropriatelyDismiss(
    _ viewController: STPPaymentOptionsViewController,
    completion: @escaping STPVoidBlock
  ) {
    if viewController.stp_isAtRootOfNavigationController() {
      // if we're the root of the navigation controller, we've been presented modally.
      viewController.presentingViewController?.dismiss(
        animated: transitionAnimationsEnabled()
      ) {
        self.paymentOptionsViewController = nil
        completion()
      }
    } else {
      // otherwise, we've been pushed onto the stack.
      var destinationViewController = hostViewController
      // If hostViewController is a nav controller, pop to the original VC on top of the stack.
      if hostViewController is UINavigationController {
        destinationViewController = originalTopViewController
      }
      viewController.navigationController?.stp_pop(
        to: destinationViewController,
        animated: transitionAnimationsEnabled()
      ) {
        self.paymentOptionsViewController = nil
        completion()
      }
    }
  }

  // MARK: - Shipping Info

  func presentShippingViewController(withNewState state: STPPaymentContextState) {
    assert(
      hostViewController != nil && hostViewController?.viewIfLoaded?.window != nil,
      "hostViewController must not be nil on STPPaymentContext when calling presentShippingViewController on it. Next time, set the hostViewController property first!"
    )

    if self.state == STPPaymentContextState.none {
      self.state = state

      let addressViewController = STPShippingAddressViewController(paymentContext: self)
      addressViewController.navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
      let navigationController = UINavigationController(rootViewController: addressViewController)
      navigationController.navigationBar.stp_theme = theme
      navigationController.navigationBar.prefersLargeTitles = true
      navigationController.modalPresentationStyle = modalPresentationStyle
      hostViewController?.present(
        navigationController,
        animated: transitionAnimationsEnabled())
    }
  }

  @objc
  public func shippingAddressViewControllerDidCancel(
    _ addressViewController: STPShippingAddressViewController
  ) {
    appropriatelyDismiss(addressViewController) {
      if self.state == .requestingPayment {
        self.didFinish(
          with: .userCancellation,
          error: nil)
      } else {
        self.state = STPPaymentContextState.none
      }
    }
  }

  @objc
  public func shippingAddressViewController(
    _ addressViewController: STPShippingAddressViewController,
    didEnter address: STPAddress,
    completion: @escaping STPShippingMethodsCompletionBlock
  ) {
    if delegate?.responds(
      to: #selector(
        STPPaymentContextDelegate.paymentContext(_:didUpdateShippingAddress:completion:))) ?? false
    {
      delegate?.paymentContext?(self, didUpdateShippingAddress: address) {
        status, shippingValidationError, shippingMethods, selectedMethod in
        self.shippingMethods = shippingMethods
        completion(status, shippingValidationError, shippingMethods, selectedMethod)
      }
    } else {
      completion(.valid, nil, nil, nil)
    }
  }

  @objc
  public func shippingAddressViewController(
    _ addressViewController: STPShippingAddressViewController,
    didFinishWith address: STPAddress,
    shippingMethod method: PKShippingMethod?
  ) {
    shippingAddress = address
    shippingAddressNeedsVerification = false
    selectedShippingMethod = method
    delegate?.paymentContextDidChange(self)
    if apiAdapter.responds(
        to: #selector(STPCustomerContext.updateCustomer(withShippingAddress:completion:)))
    {
      if let shippingAddress = shippingAddress {
        apiAdapter.updateCustomer?(withShippingAddress: shippingAddress, completion: nil)
      }
    }
    appropriatelyDismiss(addressViewController) {
      if self.state == .requestingPayment {
        self.state = STPPaymentContextState.none
        self.requestPayment()
      } else {
        self.state = STPPaymentContextState.none
      }
    }
  }

  @objc(appropriatelyDismissViewController:completion:) func appropriatelyDismiss(
    _ viewController: UIViewController,
    completion: @escaping STPVoidBlock
  ) {
    if viewController.stp_isAtRootOfNavigationController() {
      // if we're the root of the navigation controller, we've been presented modally.
      viewController.presentingViewController?.dismiss(
        animated: transitionAnimationsEnabled()
      ) {
        completion()
      }
    } else {
      // otherwise, we've been pushed onto the stack.
      var destinationViewController = hostViewController
      // If hostViewController is a nav controller, pop to the original VC on top of the stack.
      if hostViewController is UINavigationController {
        destinationViewController = originalTopViewController
      }
      viewController.navigationController?.stp_pop(
        to: destinationViewController,
        animated: transitionAnimationsEnabled()
      ) {
        completion()
      }
    }
  }

  // MARK: - Request Payment
  func requestPaymentShouldPresentShippingViewController() -> Bool {
    let shippingAddressRequired = (configuration.requiredShippingAddressFields?.count ?? 0) > 0
    var shippingAddressIncomplete: Bool?
    if let requiredShippingAddressFields1 = configuration.requiredShippingAddressFields {
      shippingAddressIncomplete =
        !(shippingAddress?.containsRequiredShippingAddressFields(requiredShippingAddressFields1)
        ?? false)
    }
    let shippingMethodRequired =
      configuration.shippingType == .shipping
      && delegate?.responds(
        to: #selector(
          STPPaymentContextDelegate.paymentContext(_:didUpdateShippingAddress:completion:)))
        ?? false
      && selectedShippingMethod == nil
    let verificationRequired =
      configuration.verifyPrefilledShippingAddress && shippingAddressNeedsVerification
    // true if STPShippingVC should be presented to collect or verify a shipping address
    let shouldPresentShippingAddress =
      shippingAddressRequired && (shippingAddressIncomplete ?? false || verificationRequired)
    // this handles a corner case where STPShippingVC should be presented because:
    // - shipping address has been pre-filled
    // - no verification is required, but the user still needs to enter a shipping method
    let shouldPresentShippingMethods =
      shippingAddressRequired && !(shippingAddressIncomplete ?? false) && !verificationRequired
      && shippingMethodRequired
    return shouldPresentShippingAddress || shouldPresentShippingMethods
  }

  func didFinish(
    with status: STPPaymentStatus,
    error: Error?
  ) {
    state = STPPaymentContextState.none
    delegate?.paymentContext(
      self,
      didFinishWith: status,
      error: error)
  }

  func buildPaymentRequest() -> PKPaymentRequest? {
    guard let appleMerchantIdentifier = configuration.appleMerchantIdentifier, paymentAmount > 0 else {
      return nil
    }
    let paymentRequest = StripeAPI.paymentRequest(
      withMerchantIdentifier: appleMerchantIdentifier,
      country: paymentCountry, currency: paymentCurrency )

    let summaryItems = paymentSummaryItems
    paymentRequest.paymentSummaryItems = summaryItems

    let requiredFields = STPAddress.applePayContactFields(from: configuration.requiredBillingAddressFields)
    paymentRequest.requiredBillingContactFields = requiredFields

    var shippingRequiredFields: Set<PKContactField>?
    if let requiredShippingAddressFields1 = configuration.requiredShippingAddressFields {
      shippingRequiredFields = STPAddress.pkContactFields(
        fromStripeContactFields: requiredShippingAddressFields1)
    }
    if let shippingRequiredFields = shippingRequiredFields {
      paymentRequest.requiredShippingContactFields = shippingRequiredFields
    }

    paymentRequest.currencyCode = paymentCurrency.uppercased()
    if let selectedShippingMethod = selectedShippingMethod {
      var orderedShippingMethods = shippingMethods
      orderedShippingMethods?.removeAll { $0 as AnyObject === selectedShippingMethod as AnyObject }
      orderedShippingMethods?.insert(selectedShippingMethod, at: 0)
      paymentRequest.shippingMethods = orderedShippingMethods
    } else {
      paymentRequest.shippingMethods = shippingMethods
    }

    paymentRequest.shippingType = STPPaymentContext.pkShippingType(configuration.shippingType)

    if let shippingAddress = shippingAddress {
      paymentRequest.shippingContact = shippingAddress.pkContactValue()
    }
    return paymentRequest
  }

  class func pkShippingType(_ shippingType: STPShippingType) -> PKShippingType {
    switch shippingType {
    case .shipping:
      return .shipping
    case .delivery:
      return .delivery
    }
  }

  func artificiallyRetain(_ host: NSObject) {
    objc_setAssociatedObject(
      host, UnsafeRawPointer(&kSTPPaymentCoordinatorAssociatedObjectKey), self,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }

  // MARK: - STPAuthenticationContext
  @objc
  public func authenticationPresentingViewController() -> UIViewController {
    return hostViewController!
  }

  @objc
  public func prepare(forPresentation completion: @escaping STPVoidBlock) {
    if applePayVC != nil && applePayVC?.presentingViewController != nil {
      hostViewController?.dismiss(
        animated: transitionAnimationsEnabled()
      ) {
        completion()
      }
    } else {
      completion()
    }
  }
}

/// Implement `STPPaymentContextDelegate` to get notified when a payment context changes, finishes, encounters errors, etc. In practice, if your app has a "checkout screen view controller", that is a good candidate to implement this protocol.
@objc public protocol STPPaymentContextDelegate: NSObjectProtocol {
  /// Called when the payment context encounters an error when fetching its initial set of data. A few ways to handle this are:
  /// - If you're showing the user a checkout page, dismiss the checkout page when this is called and present the error to the user.
  /// - Present the error to the user using a `UIAlertController` with two buttons: Retry and Cancel. If they cancel, dismiss your UI. If they Retry, call `retryLoading` on the payment context.
  /// To make it harder to get your UI into a bad state, this won't be called until the context's `hostViewController` has finished appearing.
  /// - Parameters:
  ///   - paymentContext: the payment context that encountered the error
  ///   - error:          the error that was encountered
  func paymentContext(_ paymentContext: STPPaymentContext, didFailToLoadWithError error: Error)
  /// This is called every time the contents of the payment context change. When this is called, you should update your app's UI to reflect the current state of the payment context. For example, if you have a checkout page with a "selected payment method" row, you should update its payment method with `paymentContext.selectedPaymentOption.label`. If that checkout page has a "buy" button, you should enable/disable it depending on the result of `paymentContext.isReadyForPayment`.
  /// - Parameter paymentContext: the payment context that changed
  func paymentContextDidChange(_ paymentContext: STPPaymentContext)
  /// Inside this method, you should make a call to your backend API to make a PaymentIntent with that Customer + payment method, and invoke the `completion` block when that is done.
  /// - Parameters:
  ///   - paymentContext: The context that succeeded
  ///   - paymentResult:  Information associated with the payment that you can pass to your server. You should go to your backend API with this payment result and use the PaymentIntent API to complete the payment. See https://stripe.com/docs/mobile/ios/standard#submit-payment-intents. Once that's done call the `completion` block with any error that occurred (or none, if the payment succeeded). - seealso: STPPaymentResult.h
  ///   - completion:     Call this block when you're done creating a payment intent (or subscription, etc) on your backend. If it succeeded, call `completion(STPPaymentStatusSuccess, nil)`. If it failed with an error, call `completion(STPPaymentStatusError, error)`. If the user canceled, call `completion(STPPaymentStatusUserCancellation, nil)`.
  func paymentContext(
    _ paymentContext: STPPaymentContext,
    didCreatePaymentResult paymentResult: STPPaymentResult,
    completion: @escaping STPPaymentStatusBlock
  )
  /// This is invoked by an `STPPaymentContext` when it is finished. This will be called after the payment is done and all necessary UI has been dismissed. You should inspect the returned `status` and behave appropriately. For example: if it's `STPPaymentStatusSuccess`, show the user a receipt. If it's `STPPaymentStatusError`, inform the user of the error. If it's `STPPaymentStatusUserCancellation`, do nothing.
  /// - Parameters:
  ///   - paymentContext: The payment context that finished
  ///   - status:         The status of the payment - `STPPaymentStatusSuccess` if it succeeded, `STPPaymentStatusError` if it failed with an error (in which case the `error` parameter will be non-nil), `STPPaymentStatusUserCancellation` if the user canceled the payment.
  ///   - error:          An error that occurred, if any.
  func paymentContext(
    _ paymentContext: STPPaymentContext,
    didFinishWith status: STPPaymentStatus,
    error: Error?
  )

  /// Inside this method, you should verify that you can ship to the given address.
  /// You should call the completion block with the results of your validation
  /// and the available shipping methods for the given address. If you don't implement
  /// this method, the user won't be prompted to select a shipping method and all
  /// addresses will be valid. If you call the completion block with nil or an
  /// empty array of shipping methods, the user won't be prompted to select a
  /// shipping method.
  /// @note If a user updates their shipping address within the Apple Pay dialog,
  /// this address will be anonymized. For example, in the US, it will only include the
  /// city, state, and zip code. The payment context will have the user's complete
  /// shipping address by the time `paymentContext:didFinishWithStatus:error` is
  /// called.
  /// - Parameters:
  ///   - paymentContext:  The context that updated its shipping address
  ///   - address: The current shipping address
  ///   - completion:      Call this block when you're done validating the shipping
  /// address and calculating available shipping methods. If you call the completion
  /// block with nil or an empty array of shipping methods, the user won't be prompted
  /// to select a shipping method.
  @objc optional func paymentContext(
    _ paymentContext: STPPaymentContext,
    didUpdateShippingAddress address: STPAddress,
    completion: @escaping STPShippingMethodsCompletionBlock
  )
}

/// The current state of the payment context
/// - STPPaymentContextStateNone: No view controllers are currently being shown. The payment may or may not have already been completed
/// - STPPaymentContextStateShowingRequestedViewController: The view controller that you requested the context show is being shown (via the push or present payment methods or shipping view controller methods)
/// - STPPaymentContextStateRequestingPayment: The payment context is in the middle of requesting payment. It may be showing some other UI or view controller if more information is necessary to complete the payment.
enum STPPaymentContextState: Int {
  case none
  case showingRequestedViewController
  case requestingPayment
}

private var kSTPPaymentCoordinatorAssociatedObjectKey = 0
