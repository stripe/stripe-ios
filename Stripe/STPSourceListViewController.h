//
//  STPSourceListViewController.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol STPSourceProvider;

@interface STPSourceListViewController : UIViewController

- (nonnull instancetype)initWithSourceProvider:(nonnull id<STPSourceProvider>)sourceProvider;
@property(nonatomic, readonly, nonnull)id<STPSourceProvider> sourceProvider;

@end
