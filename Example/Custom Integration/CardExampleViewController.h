//
//  CardExampleViewController.h
//  Custom Integration (ObjC)
//
//  Created by Daniel Jackson on 7/5/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ExampleViewControllerDelegate;

@interface CardExampleViewController : UIViewController

@property (nonatomic, weak) id<ExampleViewControllerDelegate> delegate;

@end
