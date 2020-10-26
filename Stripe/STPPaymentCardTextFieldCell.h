//
//  STPPaymentCardTextFieldCell.h
//  Stripe
//
//  Created by Jack Flintermann on 6/16/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPPaymentCardTextField.h"
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPPaymentCardTextFieldCell : UITableViewCell

@property (nonatomic, weak, readonly) STPPaymentCardTextField *paymentField;
@property (nonatomic, copy) STPTheme *theme;
@property (nonatomic, weak) UIView *inputAccessoryView;

- (BOOL)isEmpty;

@end

NS_ASSUME_NONNULL_END
