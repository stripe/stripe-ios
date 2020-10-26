//
//  STPValidatedTextField.h
//  StripeiOS
//
//  Created by Daniel Jackson on 12/14/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 A UITextField that changes the text color, based on the validity of
 its contents.

 This does *not* (currently?) have any logic or hooks for determining whether
 the contents are valid, that must be done by something else.
 */
@interface STPValidatedTextField : UITextField

/// color to use for `text` when `validText` is YES
@property (nonatomic, readwrite, nullable) UIColor *defaultColor;
/// color to use for `text` when `validText` is NO
@property (nonatomic, readwrite, nullable) UIColor *errorColor;
/// color to use for `placeholderText`, displayed when `text` is empty
@property (nonatomic, readwrite, nullable) UIColor *placeholderColor;

/// flag to indicate whether the contents are valid or not.
@property (nonatomic, readwrite, assign) BOOL validText;

@end
