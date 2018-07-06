//
//  BrowseExamplesViewController.h
//  Custom Integration (ObjC)
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

typedef void (^STPSourceSubmissionHandler)(STPBackendResult status, NSError *error);

@protocol ExampleViewControllerDelegate <NSObject>

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message;
- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error;
- (void)createBackendChargeWithSource:(NSString *)sourceID completion:(STPSourceSubmissionHandler)completion;

@end

@interface BrowseExamplesViewController : UITableViewController

@end
