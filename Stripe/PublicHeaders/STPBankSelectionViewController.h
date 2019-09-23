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

/**
 The payment methods supported by STPBankSelectionViewController.
 */
typedef NS_ENUM(NSInteger, STPBankSelectionMethod) {
    
    /**
     FPX (Malaysia)
     */
    STPBankSelectionMethodFPX,
    
    /**
     An unknown payment method
     */
    STPBankSelectionMethodUnknown,
};

/** This view controller displays a list of banks of the specified type, allowing the user to select one to pay from.
    Once a bank is selected, it will return a PaymentMethodParams object, which you can use to confirm a PaymentIntent
    or inspect to obtain details about the selected bank.
*/
@interface STPBankSelectionViewController : STPCoreTableViewController

/**
 A convenience initializer; equivalent to calling `initWithBankMethod:bankMethod configuration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme]`.
 */
- (instancetype)initWithBankMethod:(STPBankSelectionMethod)bankMethod;

/**
 Initializes a new `STPBankSelectionViewController` with the provided configuration and theme. Don't forget to set the `delegate` property after initialization.

 @param bankMethod The user will be presented with a list of banks for this payment method. STPBankSelectionMethodFPX is currently the only supported payment method.
 @param configuration The configuration to use. This determines the Stripe publishable key to use when querying metadata about the banks. @see STPPaymentConfiguration
 @param theme         The theme to use to inform the view controller's visual appearance. @see STPTheme
 */
- (instancetype)initWithBankMethod:(STPBankSelectionMethod)bankMethod
                     configuration:(STPPaymentConfiguration *)configuration
                             theme:(STPTheme *)theme;

/**
The view controller's delegate. This must be set before showing the view controller in order for it to work properly. @see STPBankSelectionViewControllerDelegate
*/
@property (nonatomic, weak) id<STPBankSelectionViewControllerDelegate> delegate;

@end

/**
An `STPBankSelectionViewControllerDelegate` is notified when a user selects a bank.
*/
@protocol STPBankSelectionViewControllerDelegate <NSObject>

/**
This is called when the user selects a bank.

You can use the returned PaymentMethodParams to confirm a PaymentIntent, or inspect
 it to obtain details about the selected bank.
 Once you're done, you'll want to dismiss (or pop) the view controller.

@param bankViewController          the view controller that created the PaymentMethodParams
@param paymentMethodParams         the PaymentMethodParams that was created. @see STPPaymentMethodParams
*/
- (void)bankSelectionViewController:(STPBankSelectionViewController *)bankViewController
       didCreatePaymentMethodParams:(STPPaymentMethodParams *)paymentMethodParams;

@end

NS_ASSUME_NONNULL_END
