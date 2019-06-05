//
//  SofortExampleViewController.h
//  Custom Integration
//
//  Created by Ben Guo on 2/22/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

@interface SofortExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end
