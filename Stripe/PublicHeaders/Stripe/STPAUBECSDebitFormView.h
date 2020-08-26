//
//  STPAUBECSDebitFormView.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPMultiFormTextField.h"

NS_ASSUME_NONNULL_BEGIN

@class STPAUBECSDebitFormView;
@class STPPaymentMethodParams;

/**
 STPAUBECSDebitFormViewDelegate provides methods for STPAUBECSDebitFormView to inform its delegate
 of when the form has been completed.
 */
@protocol STPAUBECSDebitFormViewDelegate <NSObject>

/**
 Called when the form transitions from complete to incomplete or vice-versa.
 @param form The `STPAUBECSDebitFormView` instance whose completion state has changed
 @param complete Whether the form is considered complete and can generate an `STPPaymentMethodParams` instance.
 */
- (void)auBECSDebitForm:(STPAUBECSDebitFormView *)form didChangeToStateComplete:(BOOL)complete;

@end

/**
 STPAUBECSDebitFormView is a subclass of UIControl that contains all of the necessary fields and legal text for collecting AU BECS Debit payments.
 For additional customization options @see STPFormTextFieldContainer
 */
@interface STPAUBECSDebitFormView : STPMultiFormTextField

/**
  @param companyName The name of the company collecting AU BECS Debit payment details information. This will be used to provide the required service agreement text. @see https://stripe.com/au-becs/legal
 */
- (instancetype)initWithCompanyName:(NSString *)companyName NS_DESIGNATED_INITIALIZER;

/**
 Use initWithCompanyName instead.
 */
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

/**
 Use initWithCompanyName instead.
 */
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;

/**
 The background color for the form text fields. Defaults to [UIColor systemBackgroundColor] on iOS 13.0 and later, [UIColor whiteColor] on earlier iOS versions.

 Set this property to nil to reset to the default.
 */
@property (nonatomic, copy, null_resettable) UIColor *formBackgroundColor UI_APPEARANCE_SELECTOR;

/**
 The delegate to inform about changes to this STPAUBECSDebitFormView instance.
 */
@property (nonatomic, weak) id<STPAUBECSDebitFormViewDelegate> becsDebitFormDelegate;

/**
 This property will return a non-nil value if and only if the form is in a complete state. The `STPPaymentMethodParams` instance
 will have it's `auBECSDebit` property populated with the values input in this form.
 */
@property (nonatomic, nullable, readonly) STPPaymentMethodParams *paymentMethodParams;

@end

NS_ASSUME_NONNULL_END
