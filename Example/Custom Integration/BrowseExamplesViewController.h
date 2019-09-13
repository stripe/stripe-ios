//
//  BrowseExamplesViewController.h
//  Custom Integration
//
//  Created by Ben Guo on 2/17/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Stripe/Stripe.h>

@protocol ExampleViewControllerDelegate <STPAuthenticationContext>

- (void)exampleViewController:(UIViewController *)controller didFinishWithMessage:(NSString *)message;
- (void)exampleViewController:(UIViewController *)controller didFinishWithError:(NSError *)error;

@end

@interface BrowseExamplesViewController : UITableViewController

@end
