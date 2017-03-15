//
//  STPAPIClient.h
//  StripeExample
//
//  Created by Jack Flintermann on 12/18/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

#define FAUXPAS_IGNORED_ON_LINE(...)
#define FAUXPAS_IGNORED_IN_FILE(...)
FAUXPAS_IGNORED_IN_FILE(APIAvailability)

static NSString *const STPSDKVersion = @"10.0.1";

@class STPBankAccount, STPBankAccountParams, STPCard, STPCardParams, STPSourceParams, STPToken, STPPaymentConfiguration;

/**
 A top-level class that imports the rest of the Stripe SDK.
 */
@interface Stripe : NSObject FAUXPAS_IGNORED_ON_LINE(UnprefixedClass);

/**
 *  Set your Stripe API key with this method. New instances of STPAPIClient will be initialized with this value. You should call this method as early as
 *  possible in your application's lifecycle, preferably in your AppDelegate.
 *
 *  @param   publishableKey Your publishable key, obtained from https://stripe.com/account/apikeys
 *  @warning Make sure not to ship your test API keys to the App Store! This will log a warning if you use your test key in a release build.
 */
+ (void)setDefaultPublishableKey:(NSString *)publishableKey;

/// The current default publishable key.
+ (nullable NSString *)defaultPublishableKey;

/**
 *  By default, Stripe collects some basic information about SDK usage.
 *  You can call this method to turn off analytics collection.
 */
+ (void)disableAnalytics;

@end

/// A client for making connections to the Stripe API.
@interface STPAPIClient : NSObject

/**
 *  A shared singleton API client. Its API key will be initially equal to [Stripe defaultPublishableKey].
 */
+ (instancetype)sharedClient;
- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithPublishableKey:(NSString *)publishableKey;

/**
 *  @see [Stripe setDefaultPublishableKey:]
 */
@property (nonatomic, copy, nullable) NSString *publishableKey;

/**
 *  @see -initWithConfiguration
 */
@property (nonatomic, copy) STPPaymentConfiguration *configuration;

@end

#pragma mark Bank Accounts

/**
 *  STPAPIClient extensions to create Stripe tokens from bank accounts.
 */
@interface STPAPIClient (BankAccounts)

/**
 *  Converts an STPBankAccount object into a Stripe token using the Stripe API.
 *
 *  @param bankAccount The user's bank account details. Cannot be nil. @see https://stripe.com/docs/api#create_bank_account_token
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithBankAccount:(STPBankAccountParams *)bankAccount completion:(__nullable STPTokenCompletionBlock)completion;

@end

#pragma mark Credit Cards

/**
 *  STPAPIClient extensions to create Stripe tokens from credit or debit cards.
 */
@interface STPAPIClient (CreditCards)

/**
 *  Converts an STPCardParams object into a Stripe token using the Stripe API.
 *
 *  @param card        The user's card details. Cannot be nil. @see https://stripe.com/docs/api#create_card_token
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithCard:(STPCardParams *)card completion:(nullable STPTokenCompletionBlock)completion;

@end

/**
 *  Convenience methods for working with Apple Pay.
 */
@interface Stripe(ApplePay)

/**
 *  Whether or not this device is capable of using Apple Pay. This checks both whether the user is running an iPhone 6/6+ or later, iPad Air 2 or later, or iPad
 *mini 3 or later, as well as whether or not they have stored any cards in Apple Pay on their device.
 *
 *  @param paymentRequest The return value of this method depends on the `supportedNetworks` property of this payment request, which by default should be
 *`@[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa, PKPaymentNetworkDiscover]`.
 *
 *  @return whether or not the user is currently able to pay with Apple Pay.
 */
+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest NS_AVAILABLE_IOS(8_0);

+ (BOOL)deviceSupportsApplePay;

/**
 *  A convenience method to return a `PKPaymentRequest` with sane default values. You will still need to configure the `paymentSummaryItems` property to indicate
 *what the user is purchasing, as well as the optional `requiredShippingAddressFields`, `requiredBillingAddressFields`, and `shippingMethods` properties to indicate
 *what contact information your application requires.
 *
 *  @param merchantIdentifier Your Apple Merchant ID, as obtained at https://developer.apple.com/account/ios/identifiers/merchant/merchantCreate.action
 *
 *  @return a `PKPaymentRequest` with proper default values. Returns nil if running on < iOS8.
 */
+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier NS_AVAILABLE_IOS(8_0);

@end

#pragma mark Sources

/**
 *  STPAPIClient extensions for working with Source objects
 */
@interface STPAPIClient (Sources)

/**
 *  Creates a Source object using the provided details.
 *
 *  @param params      The details of the source to create. Cannot be nil. @see https://stripe.com/docs/api#create_source
 *  @param completion  The callback to run with the returned Source object, or an error.
 */
- (void)createSourceWithParams:(STPSourceParams *)params completion:(STPSourceCompletionBlock)completion;

/**
 *  Retrieves the Source object with the given ID. @see https://stripe.com/docs/api#retrieve_source
 *
 *  @param identifier  The identifier of the source to be retrieved. Cannot be nil.
 *  @param secret      The client secret of the source. Cannot be nil.
 *  @param completion  The callback to run with the returned Source object, or an error.
 */
- (void)retrieveSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret completion:(STPSourceCompletionBlock)completion;

/**
 *  Starts polling the Source object with the given ID. For payment methods that require
 *  additional customer action (e.g. authorizing a payment with their bank), polling
 *  allows you to determine if the action was successful. Polling will stop and the
 *  provided callback will be called once the source's status is no longer `pending`,
 *  or if the given timeout is reached and the source is still `pending`. If polling
 *  stops due to an error, the callback will be fired with the latest retrieved
 *  source and the error.
 *
 *  Note that if a poll is already running for a source, subsequent calls to `startPolling`
 *  with the same source ID will do nothing.
 *
 *  @param identifier  The identifier of the source to be retrieved. Cannot be nil.
 *  @param secret      The client secret of the source. Cannot be nil.
 *  @param timeout     The timeout for the polling operation, in seconds. Timeouts are capped at 5 minutes.
 *  @param completion  The callback to run with the returned Source object, or an error.
 */
- (void)startPollingSourceWithId:(NSString *)identifier clientSecret:(NSString *)secret timeout:(NSTimeInterval)timeout completion:(STPSourceCompletionBlock)completion NS_EXTENSION_UNAVAILABLE("Source polling is not available in extensions");;

/**
 *  Stops polling the Source object with the given ID. Note that the completion block passed to
 *  `startPolling` will not be fired when `stopPolling` is called.
 *
 *  @param identifier  The identifier of the source to be retrieved. Cannot be nil.
 */
- (void)stopPollingSourceWithId:(NSString *)identifier NS_EXTENSION_UNAVAILABLE("Source polling is not available in extensions");;

@end


NS_ASSUME_NONNULL_END
