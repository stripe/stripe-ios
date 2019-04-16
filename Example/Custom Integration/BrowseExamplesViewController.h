//
//  BrowseExamplesViewController.h
//  Custom Integration (Recommended)
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
typedef void (^STPPaymentIntentCreateAndConfirmHandler)(STPBackendResult status, STPPaymentIntent *paymentIntent, NSError *error);
typedef void (^STPRedirectCompletionHandler)(STPPaymentIntent *retrievedIntent, NSError *error);
typedef void (^STPConfirmPaymentIntentCompletionHandler)(STPBackendResult status, STPPaymentIntent *paymentIntent, NSError *error);


@protocol ExampleViewControllerDelegate <NSObject>

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message;
- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error;
- (void)performRedirectForViewController:(UIViewController *)controller
                       withPaymentIntent:(STPPaymentIntent *)paymentIntent
                              completion:(STPRedirectCompletionHandler)completion;

- (void)createBackendPaymentIntentWithAmount:(NSNumber *)amount completion:(STPPaymentIntentCreationHandler)completion;
- (void)createAndConfirmPaymentIntentWithAmount:(NSNumber *)amount
                                  paymentMethod:(NSString *)paymentMethodID
                                      returnURL:(NSString *)returnURL
                                     completion:(STPPaymentIntentCreateAndConfirmHandler)completion;
- (void)confirmPaymentIntent:(STPPaymentIntent *)paymentIntent completion:(STPConfirmPaymentIntentCompletionHandler)completion;

@end

@interface BrowseExamplesViewController : UITableViewController

@end
