//
//  STPMultiFormTextField.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPFormTextFieldContainer.h"

@class STPFormTextField;

NS_ASSUME_NONNULL_BEGIN

@class STPMultiFormTextField;

/**
 STPMultiFormFieldDelegate provides methods for a delegate to respond to editing and text changes.
 */
@protocol STPMultiFormFieldDelegate <NSObject>

/**
 Called when the text field becomes the first responder.
 */
- (void)formTextFieldDidStartEditing:(STPFormTextField *)formTextField
                    inMultiFormField:(STPMultiFormTextField *)multiFormField;

/**
 Called when the text field resigns from being the first responder.
 */
- (void)formTextFieldDidEndEditing:(STPFormTextField *)formTextField
                  inMultiFormField:(STPMultiFormTextField *)multiFormField;

/**
 Called when the text within the form text field changes.
 */
- (void)formTextFieldTextDidChange:(STPFormTextField *)formTextField
                  inMultiFormField:(STPMultiFormTextField *)multiFormField;

/**
 Called to get any additional formatting from the delegate for the string input to the form text field.
 */
- (NSAttributedString *)modifiedIncomingTextChange:(NSAttributedString *)input
                                      forTextField:(STPFormTextField *)formTextField
                                  inMultiFormField:(STPMultiFormTextField *)multiFormField;

/**
 Delegates should implement this method so that STPMultiFormTextField when the contents of the form text field renders it complete.
 */
- (BOOL)isFormFieldComplete:(STPFormTextField *)formTextField
           inMultiFormField:(STPMultiFormTextField *)multiFormField;
@end

/**
 STPMultiFormTextField is a lightweight UIView that wraps a collection of STPFormTextFields and can automatically move to the next form field when one is completed.
 */
@interface STPMultiFormTextField : UIView <STPFormTextFieldContainer>

/**
 The collection of STPFormTextFields that this instance manages.
 */
@property (nonatomic) NSArray<STPFormTextField *> *formTextFields;

/**
 The STPMultiFormTextField's delegate.
 */
@property (nonatomic, weak) id<STPMultiFormFieldDelegate> multiFormFieldDelegate;

/**
 Calling this method will make the next incomplete STPFormTextField in `formTextFields` become the first responder.
 If all of the form text fields are already complete, then the last field in `formTextFields` will become the first responder.
 */
- (void)focusNextFormField;

@end

NS_ASSUME_NONNULL_END
