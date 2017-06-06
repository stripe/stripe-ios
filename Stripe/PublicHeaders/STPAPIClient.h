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
#import "STPFile.h"

NS_ASSUME_NONNULL_BEGIN

#define FAUXPAS_IGNORED_ON_LINE(...)
#define FAUXPAS_IGNORED_IN_FILE(...)
FAUXPAS_IGNORED_IN_FILE(APIAvailability)

static NSString *const STPSDKVersion = @"10.1.0";

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

#pragma mark Personally Identifiable Information

/**
 *  STPAPIClient extensions to create Stripe tokens from a personal identification number.
 */
@interface STPAPIClient (PII)

/**
 *  Converts a personal identification number into a Stripe token using the Stripe API.
 *
 *  @param pii The user's personal identification number. Cannot be nil. @see https://stripe.com/docs/api#create_pii_token
 *  @param completion  The callback to run with the returned Stripe token (and any errors that may have occurred).
 */
- (void)createTokenWithPersonalIDNumber:(NSString *)pii completion:(__nullable STPTokenCompletionBlock)completion;

@end

/**
 *  STPAPIClient extensions to upload files.
 */
@interface STPAPIClient (Upload)


/**
 *  Uses the Stripe file upload API to upload an image. This can be used for 
 *  identity veritfication and evidence disputes.
 *
 *  @param image The image to be uploaded. The maximum allowed file size is 4MB 
 *         for identity documents and 8MB for evidence disputes. Cannot be nil. 
 *         Your image will be automatically resized down if you pass in one that
 *         is too large
 *  @param purpose The purpose of this file. This can be either an identifing 
 *         document or an evidence dispute.
 *  @param completion The callback to run with the returned Stripe file 
 *         (and any errors that may have occurred).
 *
 *  @see https://stripe.com/docs/file-upload
 */
- (void)uploadImage:(UIImage *)image
            purpose:(STPFilePurpose)purpose
         completion:(nullable STPFileCompletionBlock)completion;

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
 *  If you're accepting Apple Pay outside the US, be sure to use the variants 
 *  that accept a country parameter, as a different set of payment networks may
 *  be available in your country.
 */
@interface Stripe(ApplePay)

/**
 *  The payment networks that Stripe supports in the given country. 
 *  You should use this method to set the `supportedNetworks` property of your 
 *  `PKPaymentRequest`.
 *
 *  @param countryCode  Your two-letter ISO 3166 country code.
 *  @return an array of supported PKPaymentNetworks for the given country.
 */
+ (NSArray<NSString *> *)supportedPaymentNetworksForCountry:(NSString *)countryCode;

/**
 *  Validates the given payment request. This method checks if the payment request 
 *  is properly configured, and whether or not the device supports Apple Pay.
 *
 *  @param paymentRequest The payment request to validate. You should use
 *  the `supportedPaymentNetworksForCountry:` method to set the `supportedNetworks`
 *  property of your payment request.
 *
 *  @return whether or not the user is currently able to pay with Apple Pay.
 */
+ (BOOL)canSubmitPaymentRequest:(PKPaymentRequest *)paymentRequest NS_AVAILABLE_IOS(8_0);

/**
 *  Whether or not this device is capable of using Apple Pay. 
 *  This method checks whether Apple Pay is available on the user's hardware,
 *  as well as whether or not the device has any saved Apple Pay cards from
 *  supported payment networks.
 *
 *  Note that this method assumes you are accepting Apple Pay within the US.
 *  If you are accepting Apple Pay payments outside the US, you should use
 *  `deviceSupportsApplePayInCountry:`.
 *
 *  @return whether or not the device supports Apple Pay.
 */
+ (BOOL)deviceSupportsApplePay;

/**
 *  Whether or not this device is capable of using Apple Pay in the given country.
 *  This method checks whether Apple Pay is available on the user's hardware,
 *  as well as whether or not the device has any saved Apple Pay cards from
 *  supported payment networks.
 *
 *  @param countryCode  Your two-letter ISO 3166 country code.
 *
 *  @return whether or not the device supports Apple Pay.
 */
+ (BOOL)deviceSupportsApplePayInCountry:(NSString *)countryCode;

/**
 *  A convenience method to return a `PKPaymentRequest` with sane default values. 
 *  You will still need to configure the `paymentSummaryItems` property to indicate
 *  what the user is purchasing, as well as the optional `requiredShippingAddressFields`, 
 *  `requiredBillingAddressFields`, and `shippingMethods` properties to indicate
 *  what contact information your application requires.
 *
 *  Note that this method assumes you are accepting Apple Pay within the US.
 *  If you are accepting Apple Pay payments outside the US, you should use
 *  `paymentRequestWithMerchantIdentifier:country:`.
 *
 *  @param merchantIdentifier Your Apple Merchant ID.
 *
 *  @return a `PKPaymentRequest` with proper default values. Returns nil if running on < iOS8.
 */
+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier NS_AVAILABLE_IOS(8_0);

/**
 *  A convenience method to return a `PKPaymentRequest` with sane default values
 *  for the given country. The payment request's currency will be set to "USD".
 *  You will still need to configure the `paymentSummaryItems` property to indicate
 *  what the user is purchasing, as well as the optional `requiredShippingAddressFields`,
 *  `requiredBillingAddressFields`, and `shippingMethods` properties to indicate
 *  what contact information your application requires.
 *
 *  @param merchantIdentifier Your Apple Merchant ID.
 *  @param countryCode        Your two-letter ISO 3166 country code.
 *
 *  @return a `PKPaymentRequest` with proper default values. Returns nil if running on < iOS8.
 */
+ (PKPaymentRequest *)paymentRequestWithMerchantIdentifier:(NSString *)merchantIdentifier country:(NSString *)countryCode NS_AVAILABLE_IOS(8_0);

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

#pragma mark URL callbacks

@interface Stripe (STPURLCallbackHandlerAdditions)

/**
 *  Call this method in your app delegate whenever you receive an URL in your
 *  app delegate for a Stripe callback.
 *
 *  For convenience, you can pass all URL's you receive in your app delegate
 *  to this method first, and check the return value
 *  to easily determine whether it is a callback URL that Stripe will handle
 *  or if your app should process it normally.
 *
 *  If you are using a universal link URL, you will receive the callback in `application:continueUserActivity:restorationHandler:`
 *  To learn more about universal links, see https://developer.apple.com/library/content/documentation/General/Conceptual/AppSearch/UniversalLinks.html
 *
 *  If you are using a native scheme URL, you will receive the callback in `application:openURL:options:`
 *  To learn more about native url schemes, see https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html#//apple_ref/doc/uid/TP40007072-CH6-SW10
 *
 *  @param url The URL that you received in your app delegate
 *
 *  @return YES if the URL is expected and will be handled by Stripe. NO otherwise.
 */
+ (BOOL)handleStripeURLCallbackWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
