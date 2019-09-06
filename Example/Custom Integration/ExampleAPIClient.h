//
//  ExampleAPIClient.h
//  Custom Integration
//
//  Created by Yuki Tokuhiro on 9/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MyAPIClientResult) {
    MyAPIClientResultSuccess,
    MyAPIClientResultFailure,
};

typedef void (^STPPaymentIntentCreationHandler)(MyAPIClientResult status, NSString * _Nullable clientSecret, NSError * _Nullable error);
typedef void (^STPPaymentIntentCreateAndConfirmHandler)(MyAPIClientResult status, NSString * _Nullable clientSecret, NSError * _Nullable error);
typedef void (^STPConfirmPaymentIntentCompletionHandler)(MyAPIClientResult status, NSString * _Nullable clientSecret, NSError * _Nullable error);
typedef void (^STPCreateSetupIntentCompletionHandler)(MyAPIClientResult status, NSString * _Nullable clientSecret, NSError * _Nullable error);

@interface ExampleAPIClient : NSObject

+ (instancetype)sharedClient;

/**
 Asks our example backend to create and confirm a PaymentIntent using automatic confirmation.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.
 
 @param completion completion block called with status of backend call & the client secret if successful.
 @see https://stripe.com/docs/payments/payment-intents/ios
 */
- (void)createPaymentIntentWithCompletion:(STPPaymentIntentCreationHandler)completion;

/**
 Asks our example backend to create and confirm a PaymentIntent using manual confirmation.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.

 @see https://stripe.com/docs/payments/payment-intents/ios-manual
 @param paymentMethodID Stripe ID of the PaymentMethod representing the customer's payment method
 @param returnURL A URL to the app, used to automatically redirect customers back to your app
 after your they completes web-based authentication. See https://stripe.com/docs/mobile/ios/authentication#return-url
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)createAndConfirmPaymentIntentWithPaymentMethod:(NSString *)paymentMethodID
                                             returnURL:(NSString *)returnURL
                                            completion:(STPPaymentIntentCreateAndConfirmHandler)completion;

/**
 Asks our example backend to confirm a PaymentIntent using manual confirmation.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.
 
 @see https://stripe.com/docs/payments/payment-intents/ios-manual
 @param paymentIntentId Stripe ID of the PaymentIntent to confirm.
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)confirmPaymentIntent:(NSString *)paymentIntentID completion:(STPConfirmPaymentIntentCompletionHandler)completion;


/**
 Asks our example backend to confirm a SetupIntent.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a SetupIntent with the correct properties, and then it needs to pass the client secret back.

 @see https://stripe.com/docs/payments/cards/saving-cards-without-payment
 @param returnURL A URL to the app, used to automatically redirect customers back to your app
 after your they completes web-based authentication. See https://stripe.com/docs/mobile/ios/authentication#return-url
 @param paymentMethodID If non-nil, this will also confirm the SetupIntent on the backend
 
 */
- (void)createSetupIntentWithPaymentMethod:(nullable NSString *)paymentMethodID
                                 returnURL:(NSString *)returnURL
                                completion:(STPCreateSetupIntentCompletionHandler)completion;
@end

NS_ASSUME_NONNULL_END
