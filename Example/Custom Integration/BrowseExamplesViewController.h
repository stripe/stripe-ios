//
//  BrowseExamplesViewController.h
//  Custom Integration
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stripe/Stripe.h>

typedef NS_ENUM(NSInteger, STPBackendResult) {
    STPBackendResultSuccess,
    STPBackendResultFailure,
};

typedef void (^STPPaymentIntentCreationHandler)(STPBackendResult status, NSString *clientSecret, NSError *error);
typedef void (^STPPaymentIntentCreateAndConfirmHandler)(STPBackendResult status, NSString *clientSecret, NSError *error);
typedef void (^STPConfirmPaymentIntentCompletionHandler)(STPBackendResult status, NSString *clientSecret, NSError *error);
typedef void (^STPCreateSetupIntentCompletionHandler)(STPBackendResult status, NSString *clientSecret, NSError *error);


@protocol ExampleViewControllerDelegate <STPAuthenticationContext>

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message;
- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error;

- (void)createBackendPaymentIntentWithAmount:(NSNumber *)amount completion:(STPPaymentIntentCreationHandler)completion;
- (void)createAndConfirmPaymentIntentWithAmount:(NSNumber *)amount
                                  paymentMethod:(NSString *)paymentMethodID
                                      returnURL:(NSString *)returnURL
                                     completion:(STPPaymentIntentCreateAndConfirmHandler)completion;
- (void)confirmPaymentIntent:(STPPaymentIntent *)paymentIntent completion:(STPConfirmPaymentIntentCompletionHandler)completion;


// if paymentMethodID != nil, this will also confirm on the backend
- (void)createSetupIntentWithPaymentMethod:(NSString *)paymentMethodID
                                 returnURL:(NSString *)returnURL
                                completion:(STPCreateSetupIntentCompletionHandler)completion;

@end

@interface BrowseExamplesViewController : UITableViewController

@end
