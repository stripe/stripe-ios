//
//  CardAutomaticConfirmationViewController.h
//  Custom Integration
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

@interface CardAutomaticConfirmationViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end
