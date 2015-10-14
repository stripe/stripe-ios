//
//  STPPaymentCardTextField.h
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPCard.h"

@class STPPaymentCardTextField;

/**
 *  This protocol allows a delegate to be notified when a payment text field's contents change, which can in turn be used to take further actions depending on the validity of its contents.
 */
@protocol STPPaymentCardTextFieldDelegate <NSObject>
@optional
/**
 *  Called when either the card number, expiration, or CVC changes. At this point, one can call -isValid on the text field to determine, for example, whether or not to enable a button to submit the form. Example:
 
 - (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
      self.paymentButton.enabled = textField.isValid;
 }
 
 *
 *  @param textField the text field that has changed
 */
- (void)paymentCardTextFieldDidChange:(nonnull STPPaymentCardTextField *)textField;

@end


/**
 *  STPPaymentCardTextField is a text field with similar properties to UITextField, but specialized for collecting credit/debit card information. It manages multiple UITextFields under the hood to collect this information. It's designed to fit on a single line, and from a design perspective can be used anywhere a UITextField would be appropriate.
 */
@interface STPPaymentCardTextField : UIControl

/**
 *  @see STPPaymentCardTextFieldDelegate
 */
@property(nonatomic, weak, nullable) IBOutlet id<STPPaymentCardTextFieldDelegate> delegate;

/**
 *  The font used in each child field. Default is [UIFont systemFontOfSize:18]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) UIFont *font UI_APPEARANCE_SELECTOR;

/**
 *  The text color to be used when entering valid text. Default is [UIColor blackColor]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *textColor UI_APPEARANCE_SELECTOR;

/**
 *  The text color to be used when the user has entered invalid information, such as an invalid card number. Default is [UIColor redColor]. Set this property to nil to reset to the default.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *textErrorColor UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The text placeholder color used in each child field. Default is [UIColor lightGreyColor]. Set this property to nil to reset to the default. On iOS 7 and above, this will also set the color of the card placeholder icon.
 */
@property(nonatomic, copy, null_resettable) IBInspectable UIColor *placeholderColor UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The placeholder for the card number field. Default is @"1234567812345678". If this is set to something that resembles a card number, it will automatically format it as such (in other words, you don't need to add spaces to this string).
 */
@property(nonatomic, copy, nullable) NSString *numberPlaceholder;

/**
 *  The placeholder for the expiration field. Defaults to @"MM/YY".
 */
@property(nonatomic, copy, nullable) NSString *expirationPlaceholder;

/**
 *  The placeholder for the cvc field. Defaults to @"CVC".
 */
@property(nonatomic, copy, nullable) NSString *cvcPlaceholder;

/**
 *  The border color for the field. Default is [UIColor lightGreyColor]. Can be nil (in which case no border will be drawn).
 */
@property(nonatomic, copy, nullable) IBInspectable UIColor *borderColor UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The width of the field's border. Default is 1.0.
 */
@property(nonatomic, assign) IBInspectable CGFloat borderWidth UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The corner radius for the field's border. Default is 5.0.
 */
@property(nonatomic, assign) IBInspectable CGFloat cornerRadius UI_APPEARANCE_SELECTOR IBInspectable;

/**
 *  The keyboard appearance for the field. Default is UIKeyboardAppearanceDefault.
 */
@property(nonatomic, assign) IBInspectable UIKeyboardAppearance keyboardAppearance UI_APPEARANCE_SELECTOR;

/**
 *  This behaves identically to setting the inputAccessoryView for each child text field.
 */
@property(nonatomic, strong, nullable) UIView *inputAccessoryView;

/**
 *  Causes the text field to begin editing. Presents the keyboard.
 *
 *  @return Whether or not the text field successfully began editing.
 *  @see UIResponder
 */
- (BOOL)becomeFirstResponder;

/**
 *  Causes the text field to stop editing. Dismisses the keyboard.
 *
 *  @return Whether or not the field successfully stopped editing.
 *  @see UIResponder
 */
- (BOOL)resignFirstResponder;

/**
 *  Resets all of the contents of all of the fields. If the field is currently being edited, the number field will become selected.
 */
- (void)clear;

/**
 *  Whether or not the form currently contains a valid card number, expiration date, and CVC.
 *  @see STPCardValidator
 */
@property(nonatomic, readonly, getter=isValid)BOOL valid;

/**
 *  Enable/disable selecting or editing the field. Useful when submitting card details to Stripe.
 */
@property(nonatomic, getter=isEnabled) BOOL enabled;

/**
 *  The current card number displayed by the field. May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly, nullable) NSString *cardNumber;

/**
 *  The current expiration month displayed by the field (1 = January, etc). May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly) NSUInteger expirationMonth;

/**
 *  The current expiration year displayed by the field, modulo 100 (e.g. the year 2015 will be represented as 15). May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly) NSUInteger expirationYear;

/**
 *  The current card CVC displayed by the field. May or may not be valid, unless isValid is true, in which case it is guaranteed to be valid.
 */
@property(nonatomic, readonly, nullable) NSString *cvc;

/**
 *  Convenience method to create a STPCard from the currently entered information. Will return nil if not valid.
 */
@property(nonatomic, readonly, nullable) STPCardParams *card;

@end

#pragma mark - PaymentKit compatibility

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

__attribute__((deprecated("This class is provided only for backwards-compatibility with PaymentKit. You shouldn't use it - use STPCard instead.")))
@interface PTKCard : STPCard
@end

@class PTKView;

__attribute__((deprecated("This protocol is provided only for backwards-compatibility with PaymentKit. You shouldn't use it - use STPPaymentCardTextFieldDelegate instead.")))
@protocol PTKViewDelegate <STPPaymentCardTextFieldDelegate>

@optional
- (void)paymentView:(nonnull PTKView *)paymentView withCard:(nonnull PTKCard *)card isValid:(BOOL)valid;

@end

__attribute__((deprecated("This class is provided only for backwards-compatibility with PaymentKit. You shouldn't use it - use STPPaymentCardTextField instead.")))
@interface PTKView : STPPaymentCardTextField
@property(nonatomic, weak, nullable)id<PTKViewDelegate>delegate;
@property(nonatomic, readonly, nonnull) PTKCard *card;
@end

#pragma clang diagnostic pop
