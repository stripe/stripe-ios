//
//  STPAPIClient+Private.h
//  Stripe
//
//  Created by Jack Flintermann on 10/14/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STPAPIClient.h"
#import "STPAPIRequest.h"

@class STDSAuthenticationRequestParameters;
@class STP3DS2AuthenticateResponse;
@class STPEphemeralKey;

NS_ASSUME_NONNULL_BEGIN

@interface STPAPIClient ()

+ (NSString *)apiVersion;

- (void)createTokenWithParameters:(NSDictionary *)parameters
                       completion:(STPTokenCompletionBlock)completion;


@property (nonatomic, strong, readwrite) NSURL *apiURL;
@property (nonatomic, strong, readonly) NSURLSession *urlSession;

- (NSMutableURLRequest *)configuredRequestForURL:(NSURL *)url;

+ (NSURLSessionConfiguration *)sharedUrlSessionConfiguration;

@end

@interface STPAPIClient (SourcesPrivate)

- (NSURLSessionDataTask *)retrieveSourceWithId:(NSString *)identifier
                                  clientSecret:(NSString *)secret
                            responseCompletion:(STPAPIResponseBlock)completion;

@end

@interface STPAPIClient (EphemeralKeys)
+ (instancetype)apiClientWithEphemeralKey:(STPEphemeralKey *)key;
@end

@interface STPAPIClient (Customers)

/**
 Retrieve a customer

 @see https://stripe.com/docs/api#retrieve_customer
 */
+ (void)retrieveCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
                      completion:(STPCustomerCompletionBlock)completion;

/**
 Add a source to a customer

 @see https://stripe.com/docs/api#create_card
 */
+ (void)addSource:(NSString *)sourceID
toCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
       completion:(STPSourceProtocolCompletionBlock)completion;

/**
 Update a customer with parameters

 @see https://stripe.com/docs/api#update_customer
 */
+ (void)updateCustomerWithParameters:(NSDictionary *)parameters
                            usingKey:(STPEphemeralKey *)ephemeralKey
                          completion:(STPCustomerCompletionBlock)completion;

/**
 Delete a source from a customer

 @see https://stripe.com/docs/api#delete_card
 */
+ (void)deleteSource:(NSString *)sourceID
fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
          completion:(STPErrorBlock)completion;

/**
 Attach a Payment Method to a customer
 
 @see https://stripe.com/docs/api/payment_methods/attach
 */
+ (void)attachPaymentMethod:(NSString *)paymentMethodID
         toCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
                 completion:(STPErrorBlock)completion;

/**
 Detach a Payment Method from a customer
 
 @see https://stripe.com/docs/api/payment_methods/detach
 */
+ (void)detachPaymentMethod:(NSString *)paymentMethodID
       fromCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
                 completion:(STPErrorBlock)completion;

/**
 Retrieves a list of Payment Methods attached to a customer.
 
 @note This only fetches card type Payment Methods
 */
+ (void)listPaymentMethodsForCustomerUsingKey:(STPEphemeralKey *)ephemeralKey
                                   completion:(STPPaymentMethodsCompletionBlock)completion;
@end

@interface STPAPIClient (ThreeDS2)

/**
 Kicks off 3DS2 authentication.
 */
- (void)authenticate3DS2:(STDSAuthenticationRequestParameters *)authRequestParams
        sourceIdentifier:(NSString *)sourceID
               returnURL:(nullable NSString *)returnURLString
              maxTimeout:(NSInteger)maxTimeout
              completion:(STP3DS2AuthenticateCompletionBlock)completion;

/**
 Endpoint to call to indicate that the challenge flow for a 3DS2 authentication has finished.
 */
- (void)complete3DS2AuthenticationForSource:(NSString *)sourceID completion:(STPBooleanSuccessBlock)completion;

@end

@interface Stripe (Private)

+ (NSArray<NSString *> *)supportedPKPaymentNetworks;

@end
NS_ASSUME_NONNULL_END
