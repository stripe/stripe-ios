//
//  STPBankSelectionViewController.h
//  Stripe
//
//  Created by David Estes on 8/9/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>
#import "STPCoreTableViewController.h"
#import "STPFPXBankBrand.h"
#import "STPPaymentConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPBankSelectionViewControllerDelegate;
@class STPPaymentMethodParams;

@interface STPBankSelectionViewController : STPCoreTableViewController

- (instancetype)initWithBankType:(STPBankType)bankType
                   configuration:(STPPaymentConfiguration *)configuration
                           theme:(STPTheme *)theme;

@property (nonatomic, weak) id<STPBankSelectionViewControllerDelegate> delegate;

@end

@protocol STPBankSelectionViewControllerDelegate <NSObject>

- (void)bankSelectionViewController:(STPBankSelectionViewController *)bankViewController
       didCreatePaymentMethodParams:(STPPaymentMethodParams *)paymentMethodParams
                         completion:(STPErrorBlock)completion;

@end

NS_ASSUME_NONNULL_END
