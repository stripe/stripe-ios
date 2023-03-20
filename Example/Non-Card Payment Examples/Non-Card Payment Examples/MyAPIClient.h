//
//  ExampleAPIClient.h
//  Non-Card Payment Examples
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
typedef void (^STPPaymentIntentCreateAndConfirmHandler)(MyAPIClientResult status, BOOL requiresAction, NSString * _Nullable clientSecret, NSError * _Nullable error);
typedef void (^STPConfirmPaymentIntentCompletionHandler)(MyAPIClientResult status, NSError * _Nullable error);
typedef void (^STPCreateSetupIntentCompletionHandler)(MyAPIClientResult status, NSString * _Nullable clientSecret, NSError * _Nullable error);

@interface MyAPIClient : NSObject

+ (instancetype)sharedClient;

#pragma mark - PaymentIntents (automatic confirmation)

/**
 Asks our example backend to create and confirm a PaymentIntent using automatic confirmation.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.
 
 @param additionalParameters additional parameters to pass to the example backend
 @param completion completion block called with status of backend call & the client secret if successful.
 @see https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet
 */
- (void)createPaymentIntentWithCompletion:(STPPaymentIntentCreationHandler)completion additionalParameters:(NSString * _Nullable)additionalParameters;

#pragma mark - PaymentIntents (manual confirmation)

/**
 Asks our example backend to create and confirm a PaymentIntent using manual confirmation.
 
 The implementation of this function is not interesting or relevant to using PaymentIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a PaymentIntent with the correct properties, and then it needs to pass the client secret back.

 @param paymentMethodID Stripe ID of the PaymentMethod representing the customer's payment method
 @param returnURL A URL to the app, used to automatically redirect customers back to your app
 after your they completes web-based authentication. See https://stripe.com/docs/payments/3d-secure#return-url
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
 
 @param paymentIntentId Stripe ID of the PaymentIntent to confirm.
 @param completion completion block called with status of backend call. If the status is .success, the confirmation succeeded.
 */
- (void)confirmPaymentIntent:(NSString *)paymentIntentID completion:(STPConfirmPaymentIntentCompletionHandler)completion;


#pragma mark - SetupIntents

/**
 Asks our example backend to create a SetupIntent.
 
 The implementation of this function is not interesting or relevant to using SetupIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a SetupIntent with the correct properties, and then it needs to pass the client secret back.

 @see https://stripe.com/docs/payments/save-and-reuse?platform=ios
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)createSetupIntentWithCompletion:(STPCreateSetupIntentCompletionHandler)completion;

/**
 Asks our example backend to create and confirm a SetupIntent.
 
 The implementation of this function is not interesting or relevant to using SetupIntents. The
 method signature is the most interesting part: you need some way to ask *your* backend to create
 a SetupIntent with the correct properties, and then it needs to pass the client secret back.
 
 @see https://stripe.com/docs/payments/save-and-reuse?platform=ios
 @param returnURL A URL to the app, used to automatically redirect customers back to your app
 after your they completes web-based authentication. See https://stripe.com/docs/payments/3d-secure#return-url
 @param paymentMethodID Stripe ID of the PaymentMethod to set up for future payments.
 @param completion completion block called with status of backend call & the client secret if successful.
 */
- (void)createAndConfirmSetupIntentWithPaymentMethod:(NSString *)paymentMethodID
                                           returnURL:(NSString *)returnURL
                                          completion:(STPCreateSetupIntentCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
