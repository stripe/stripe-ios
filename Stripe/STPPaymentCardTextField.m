//
//  STPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "STPPaymentCardTextField.h"

#import "NSArray+Stripe.h"
#import "NSString+Stripe.h"
#import "STPCardValidator+Private.h"
#import "STPFormTextField.h"
#import "STPImageLibrary.h"
#import "STPPaymentCardTextFieldViewModel.h"
#import "STPPostalCodeValidator.h"
#import "STPWeakStrongMacros.h"
#import "Stripe.h"
#import "STPLocalizationUtils.h"

@interface STPPaymentCardTextField()<STPFormTextFieldDelegate>

@property (nonatomic, readwrite, weak) UIImageView *brandImageView;
@property (nonatomic, readwrite, weak) UIView *fieldsView;
@property (nonatomic, readwrite, weak) STPFormTextField *numberField;
@property (nonatomic, readwrite, weak) STPFormTextField *expirationField;
@property (nonatomic, readwrite, weak) STPFormTextField *cvcField;
@property (nonatomic, readwrite, weak) STPFormTextField *postalCodeField;
@property (nonatomic, readwrite, strong) STPPaymentCardTextFieldViewModel *viewModel;
@property (nonatomic, readwrite, strong) STPCardParams *internalCardParams;
@property (nonatomic, strong) NSArray<STPFormTextField *> *allFields;
@property (nonatomic, readwrite, strong) STPFormTextField *sizingField;
@property (nonatomic, readwrite, strong) UILabel *sizingLabel;

/*
 These track the input parameters to the brand image setter so that we can
 later perform proper transition animations when new values are set
 */
@property (nonatomic, assign) STPCardFieldType currentBrandImageFieldType;
@property (nonatomic, assign) STPCardBrand currentBrandImageBrand;

/**
 This is a number-wrapped STPCardFieldType (or nil) that layout uses
 to determine how it should move/animate its subviews so that the chosen
 text field is fully visible.
 */
@property (nonatomic, copy) NSNumber *focusedTextFieldForLayout;

/*
 Creating and measuring the size of attributed strings is expensive so
 cache the values here.
 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *textToWidthCache;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *numberToWidthCache;

/**
 These bits lets us track beginEditing and endEditing for payment text field
 as a whole (instead of on a per-subview basis).
 
 DO NOT read this values directly. Use the return value from
 `getAndUpdateSubviewEditingTransitionStateFromCall:` which updates them all
 and returns you the correct current state for the method you are in.
 
 The state transitons in the should/did begin/end editing callbacks for all 
 our subfields. If we get a shouldEnd AND a shouldBegin before getting either's
 matching didEnd/didBegin, then we are transitioning focus between our subviews
 (and so we ourselves should not consider us to have begun or ended editing).
 
 But if we get a should and did called on their own without a matching opposite
 pair (shouldBegin/didBegin or shouldEnd/didEnd) then we are transitioning
 into/out of our subviews from/to outside of ourselves
 */
@property (nonatomic, assign) BOOL isMidSubviewEditingTransitionInternal;
@property (nonatomic, assign) BOOL receivedUnmatchedShouldBeginEditing;
@property (nonatomic, assign) BOOL receivedUnmatchedShouldEndEditing;

@end

@implementation STPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@synthesize borderColor = _borderColor;
@synthesize borderWidth = _borderWidth;
@synthesize cornerRadius = _cornerRadius;
@dynamic enabled;

CGFloat const STPPaymentCardTextFieldDefaultPadding = 13;
CGFloat const STPPaymentCardTextFieldDefaultInsets = 13;
CGFloat const STPPaymentCardTextFieldMinimumPadding = 10;

#if CGFLOAT_IS_DOUBLE
#define stp_roundCGFloat(x) round(x)
#define stp_ceilCGFloat(x) ceil(x)
#else
#define stp_roundCGFloat(x) roundf(x)
#define stp_ceilCGFloat(x) ceilf(x)
#endif

#pragma mark initializers

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // We're using ivars here because UIAppearance tracks when setters are
    // called, and won't override properties that have already been customized
    _borderColor = [self.class placeholderGrayColor];
    _cornerRadius = 5.0f;
    _borderWidth = 1.0f;
    self.layer.borderColor = [[_borderColor copy] CGColor];
    self.layer.cornerRadius = _cornerRadius;
    self.layer.borderWidth = _borderWidth;

    self.clipsToBounds = YES;

    _internalCardParams = [STPCardParams new];
    _viewModel = [STPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];
    _sizingField.formDelegate = nil;
    _sizingLabel = [UILabel new];
    
    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:self.brandImage];
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    brandImageView.tintColor = self.placeholderColor;
    self.brandImageView = brandImageView;
    
    STPFormTextField *numberField = [self buildTextField];
    if (@available(iOS 10.0, *)) {
        // This does not offer quick-type suggestions (as iOS 11.2), but does pick
        // the best keyboard (maybe other, hidden behavior?)
        numberField.textContentType = UITextContentTypeCreditCardNumber;
    }
    numberField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
    numberField.tag = STPCardFieldTypeNumber;
    numberField.accessibilityLabel = STPLocalizedString(@"card number", @"accessibility label for text field");
    self.numberField = numberField;
    self.numberPlaceholder = [self.viewModel defaultPlaceholder];

    STPFormTextField *expirationField = [self buildTextField];
    expirationField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorExpiration;
    expirationField.tag = STPCardFieldTypeExpiration;
    expirationField.alpha = 0;
    expirationField.isAccessibilityElement = NO;
    expirationField.accessibilityLabel = STPLocalizedString(@"expiration date", @"accessibility label for text field");
    self.expirationField = expirationField;
    self.expirationPlaceholder = @"MM/YY";
        
    STPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = STPCardFieldTypeCVC;
    cvcField.alpha = 0;
    cvcField.isAccessibilityElement = NO;
    self.cvcField = cvcField;
    self.cvcPlaceholder = nil;
    self.cvcField.accessibilityLabel = [self defaultCVCPlaceholder];

    STPFormTextField *postalCodeField = [self buildTextField];
    if (@available(iOS 10.0, *)) {
        postalCodeField.textContentType = UITextContentTypePostalCode;
    }
    postalCodeField.tag = STPCardFieldTypePostalCode;
    postalCodeField.alpha = 0;
    postalCodeField.isAccessibilityElement = NO;
    self.postalCodeField = postalCodeField;
    // Placeholder and appropriate keyboard typeare set by country code setter

    UIView *fieldsView = [[UIView alloc] init];
    fieldsView.clipsToBounds = YES;
    fieldsView.backgroundColor = [UIColor clearColor];
    self.fieldsView = fieldsView;

    self.allFields = @[numberField,
                       expirationField,
                       cvcField,
                       postalCodeField];
    
    [self addSubview:self.fieldsView];
    for (STPFormTextField *field in self.allFields) {
        [self.fieldsView addSubview:field];
    }

    [self addSubview:brandImageView];
    // On small screens, the number field fits ~4 numbers, and the brandImage is just as large.
    // Previously, taps on the brand image would *dismiss* the keyboard. Make it move to the numberField instead
    brandImageView.userInteractionEnabled = YES;
    [brandImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:numberField
                                                                                 action:@selector(becomeFirstResponder)]];

    self.focusedTextFieldForLayout = nil;
    [self updateCVCPlaceholder];
    [self resetSubviewEditingTransitionState];
}

- (STPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [STPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

- (void)clearSizingCache {
    self.textToWidthCache = [NSMutableDictionary new];
    self.numberToWidthCache = [NSMutableDictionary new];
}

+ (UIColor *)placeholderGrayColor {
    return [UIColor lightGrayColor];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:[backgroundColor copy]];
    self.numberField.backgroundColor = self.backgroundColor;
}

- (UIColor *)backgroundColor {
    return [super backgroundColor] ?: [UIColor whiteColor];
}

- (void)setFont:(UIFont *)font {
    _font = [font copy];
    
    for (UITextField *field in [self allFields]) {
        field.font = _font;
    }
    
    self.sizingField.font = _font;
    [self clearSizingCache];
    
    [self setNeedsLayout];
}

- (UIFont *)font {
    return _font ?: [UIFont systemFontOfSize:18];
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.defaultColor = _textColor;
    }
}

- (void)setContentVerticalAlignment:(UIControlContentVerticalAlignment)contentVerticalAlignment {
    [super setContentVerticalAlignment:contentVerticalAlignment];
    for (UITextField *field in [self allFields]) {
        field.contentVerticalAlignment = contentVerticalAlignment;
    }
    switch (contentVerticalAlignment) {
        case UIControlContentVerticalAlignmentCenter:
            self.brandImageView.contentMode = UIViewContentModeCenter;
            break;
        case UIControlContentVerticalAlignmentBottom:
            self.brandImageView.contentMode = UIViewContentModeBottom;
            break;
        case UIControlContentVerticalAlignmentFill:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
        case UIControlContentVerticalAlignmentTop:
            self.brandImageView.contentMode = UIViewContentModeTop;
            break;
    }
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor blackColor];
}

- (void)setTextErrorColor:(UIColor *)textErrorColor {
    _textErrorColor = [textErrorColor copy];
    
    for (STPFormTextField *field in [self allFields]) {
        field.errorColor = _textErrorColor;
    }
}

- (UIColor *)textErrorColor {
    return _textErrorColor ?: [UIColor redColor];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = [placeholderColor copy];
    self.brandImageView.tintColor = placeholderColor;
    
    for (STPFormTextField *field in [self allFields]) {
        field.placeholderColor = _placeholderColor;
    }
}

- (UIColor *)placeholderColor {
    return _placeholderColor ?: [self.class placeholderGrayColor];
}

- (void)setNumberPlaceholder:(NSString * __nullable)numberPlaceholder {
    _numberPlaceholder = [numberPlaceholder copy];
    self.numberField.placeholder = _numberPlaceholder;
}

- (void)setExpirationPlaceholder:(NSString * __nullable)expirationPlaceholder {
    _expirationPlaceholder = [expirationPlaceholder copy];
    self.expirationField.placeholder = _expirationPlaceholder;
}

- (void)setCvcPlaceholder:(NSString * __nullable)cvcPlaceholder {
    _cvcPlaceholder = [cvcPlaceholder copy];
    self.cvcField.placeholder = _cvcPlaceholder;
}

- (void)setPostalCodePlaceholder:(NSString *)postalCodePlaceholder {
    _postalCodePlaceholder = postalCodePlaceholder.copy;
    [self updatePostalFieldPlaceholder];
}

- (void)setPostalCodeEntryEnabled:(BOOL)postalCodeEntryEnabled {
    self.viewModel.postalCodeRequired = postalCodeEntryEnabled;
    if (postalCodeEntryEnabled
        && !self.countryCode) {
        self.countryCode = [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];
    }
}

- (BOOL)postalCodeEntryEnabled {
    return self.viewModel.postalCodeRequired;
}

- (NSString *)countryCode {
    return self.viewModel.postalCodeCountryCode;
}

- (void)setCountryCode:(NSString *)cCode {
    NSString *countryCode = cCode ?: [[NSLocale autoupdatingCurrentLocale] objectForKey:NSLocaleCountryCode];

    self.viewModel.postalCodeCountryCode = countryCode;
    [self updatePostalFieldPlaceholder];

    if ([countryCode isEqualToString:@"US"]) {
        self.postalCodeField.keyboardType = UIKeyboardTypePhonePad;
    }
    else {
        self.postalCodeField.keyboardType = UIKeyboardTypeDefault;
    }

    // This will revalidate and reformat
    [self setText:self.postalCode inField:STPCardFieldTypePostalCode];
}

- (void)updatePostalFieldPlaceholder {
    if (self.postalCodePlaceholder == nil) {
        self.postalCodeField.placeholder = [self defaultPostalFieldPlaceholderForCountryCode:self.countryCode];
    }
    else {
        self.postalCodeField.placeholder = _postalCodePlaceholder;
    }
}

- (NSString *)defaultPostalFieldPlaceholderForCountryCode:(NSString *)countryCode {
    if ([countryCode.uppercaseString isEqualToString:@"US"]) {
        return STPLocalizedString(@"ZIP", @"Short string for zip code (United States only)");
    }
    else {
        return STPLocalizedString(@"Postal", @"Short string for postal code (text used in non-US countries)");
    }
}

- (void)setCursorColor:(UIColor *)cursorColor {
    self.tintColor = cursorColor;
}

- (UIColor *)cursorColor {
    return self.tintColor;
}

- (void)setBorderColor:(UIColor * __nullable)borderColor {
    _borderColor = borderColor;
    if (borderColor) {
        self.layer.borderColor = [[borderColor copy] CGColor];
    }
    else {
        self.layer.borderColor = [[UIColor clearColor] CGColor];
    }
}

- (UIColor * __nullable)borderColor {
    return _borderColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return _cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return _borderWidth;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _keyboardAppearance = keyboardAppearance;
    for (STPFormTextField *field in [self allFields]) {
        field.keyboardAppearance = keyboardAppearance;
    }
}

- (void)setInputView:(UIView *)inputView {
    _inputView = inputView;

    for (STPFormTextField *field in [self allFields]) {
        field.inputView = inputView;
    }
}

- (void)setInputAccessoryView:(UIView *)inputAccessoryView {
    _inputAccessoryView = inputAccessoryView;
    
    for (STPFormTextField *field in [self allFields]) {
        field.inputAccessoryView = inputAccessoryView;
    }
}

#pragma mark UIControl

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    for (STPFormTextField *textField in [self allFields]) {
        textField.enabled = enabled;
    };
}

#pragma mark UIResponder & related methods

- (BOOL)isFirstResponder {
    return self.currentFirstResponderField != nil;
}

- (BOOL)canBecomeFirstResponder {
    STPFormTextField *firstResponder = [self currentFirstResponderField] ?: [self nextFirstResponderField];
    return [firstResponder canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    STPFormTextField *firstResponder = [self currentFirstResponderField] ?: [self nextFirstResponderField];
    return [firstResponder becomeFirstResponder];
}

- (nonnull STPFormTextField *)nextFirstResponderField {
    STPFormTextField *currentFirstResponder = [self currentFirstResponderField];
    if (currentFirstResponder) {
        NSUInteger index = [self.allFields indexOfObject:currentFirstResponder];
        if (index != NSNotFound) {
            STPFormTextField *nextField = [self.allFields stp_boundSafeObjectAtIndex:index + 1];
            if (self.postalCodeEntryEnabled || nextField != self.postalCodeField) {
                return nextField;
            }
        }
    }

    return [self firstInvalidSubField] ?: [self lastSubField];
}

- (nullable STPFormTextField *)firstInvalidSubField {
    if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] != STPCardValidationStateValid) {
        return self.numberField;
    }
    else if ([self.viewModel validationStateForField:STPCardFieldTypeExpiration] != STPCardValidationStateValid) {
        return self.expirationField;
    }
    else if ([self.viewModel validationStateForField:STPCardFieldTypeCVC] != STPCardValidationStateValid) {
        return self.cvcField;
    }
    else if (self.postalCodeEntryEnabled
             && [self.viewModel validationStateForField:STPCardFieldTypePostalCode] != STPCardValidationStateValid) {
        return self.postalCodeField;
    }
    else {
        return nil;
    }
}

- (nonnull STPFormTextField *)lastSubField {
    return self.postalCodeEntryEnabled ? self.postalCodeField : self.cvcField;
}

- (STPFormTextField *)currentFirstResponderField {
    for (STPFormTextField *textField in [self allFields]) {
        if ([textField isFirstResponder]) {
            return textField;
        }
    }
    return nil;
}

- (BOOL)canResignFirstResponder {
    return [self.currentFirstResponderField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [self.currentFirstResponderField resignFirstResponder];
    [self layoutViewsToFocusField:nil
                         animated:YES
                       completion:nil];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    return success;
}

- (STPFormTextField *)previousField {
    STPFormTextField *currentSubResponder = self.currentFirstResponderField;
    if (currentSubResponder) {
        NSUInteger index = [self.allFields indexOfObject:currentSubResponder];
        if (index != NSNotFound
            && index > 0) {
            return self.allFields[index - 1];
        }
    }
    return nil;
}

#pragma mark public convenience methods

- (void)clear {
    for (STPFormTextField *field in [self allFields]) {
        field.text = @"";
    }
    self.viewModel = [STPPaymentCardTextFieldViewModel new];
    [self onChange];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    [self updateCVCPlaceholder];
    WEAK(self);
    [self layoutViewsToFocusField:@(STPCardFieldTypePostalCode)
                         animated:YES
                       completion:^(__unused BOOL completed){
        STRONG(self);
        if ([self isFirstResponder]) {
            [[self numberField] becomeFirstResponder];
        }
    }];
}

- (BOOL)isValid {
    return [self.viewModel isValid];
}

- (BOOL)valid {
    return self.isValid;
}

#pragma mark readonly variables

- (NSString *)cardNumber {
    return self.viewModel.cardNumber;
}

- (NSUInteger)expirationMonth {
    return [self.viewModel.expirationMonth integerValue];
}

- (NSUInteger)expirationYear {
    return [self.viewModel.expirationYear integerValue];
}

- (NSString *)formattedExpirationMonth {
    return self.viewModel.expirationMonth;
}

- (NSString *)formattedExpirationYear {
    return self.viewModel.expirationYear;
}

- (NSString *)cvc {
    return self.viewModel.cvc;
}

- (NSString *)postalCode {
    if (self.postalCodeEntryEnabled) {
        return self.viewModel.postalCode;
    }
    else {
        return nil;
    }
}

- (STPCardParams *)cardParams {
    self.internalCardParams.number = self.cardNumber;
    self.internalCardParams.expMonth = self.expirationMonth;
    self.internalCardParams.expYear = self.expirationYear;
    self.internalCardParams.cvc = self.cvc;
    if (self.postalCodeEntryEnabled) {
        // We don't clobber any manually set address zip code that was on our params
        // if we are not showing the postal code entry field.
        self.internalCardParams.address.postalCode = self.postalCode;
    }
    return [self.internalCardParams copy];
}

- (void)setCardParams:(STPCardParams *)callersCardParams {
    /*
     Due to the way this class is written, programmatically setting field text
     behaves identically to user entering text (and will have the same forwarding 
     on to next responder logic).

     We have some custom logic here in the main accesible programmatic setter
     to dance around this a bit. First we save what is the current responder
     at the time this method was called. Later logic after text setting should be:
     1. If we were not first responder, we should still not be first responder
        (but layout might need updating depending on PAN validity)
     2. If original field is still not valid, it is still first responder
        (manually reset it back to first responder)
     3. Otherwise the first subfield with invalid text should now be first responder
     */
    STPFormTextField *originalSubResponder = self.currentFirstResponderField;

    /*
     #1031 small footgun hiding here. Use copies to protect from mutations of
     `internalCardParams` in the `cardParams` property accessor and any mutations
     the app code might make to their `callersCardParams` object.
     */
    STPCardParams *desiredCardParams = [callersCardParams copy];
    self.internalCardParams = [desiredCardParams copy];

    [self setText:desiredCardParams.number inField:STPCardFieldTypeNumber];
    BOOL expirationPresent = desiredCardParams.expMonth && desiredCardParams.expYear;
    if (expirationPresent) {
        NSString *text = [NSString stringWithFormat:@"%02lu%02lu",
                          (unsigned long)desiredCardParams.expMonth,
                          (unsigned long)desiredCardParams.expYear%100];
        [self setText:text inField:STPCardFieldTypeExpiration];
    }
    else {
        [self setText:@"" inField:STPCardFieldTypeExpiration];
    }
    [self setText:desiredCardParams.cvc inField:STPCardFieldTypeCVC];

    [self setText:desiredCardParams.address.postalCode inField:STPCardFieldTypePostalCode];

    if ([self isFirstResponder]) {
        STPCardFieldType fieldType = originalSubResponder.tag;
        STPCardValidationState state = [self.viewModel validationStateForField:fieldType];

        if (state == STPCardValidationStateValid) {
            STPFormTextField *nextField = [self firstInvalidSubField];
            if (nextField) {
                [nextField becomeFirstResponder];
            }
            else {
                [self resignFirstResponder];
            }
        }
        else {
            [originalSubResponder becomeFirstResponder];
        }
    }
    else {
        [self layoutViewsToFocusField:nil
                             animated:NO
                           completion:nil];
    }

    // update the card image, falling back to the number field image if not editing
    if ([self.expirationField isFirstResponder]) {
        [self updateImageForFieldType:STPCardFieldTypeExpiration];
    }
    else if ([self.cvcField isFirstResponder]) {
        [self updateImageForFieldType:STPCardFieldTypeCVC];
    }
    else {
        [self updateImageForFieldType:STPCardFieldTypeNumber];
    }
    [self updateCVCPlaceholder];
}

- (void)setText:(NSString *)text inField:(STPCardFieldType)field {
    NSString *nonNilText = text ?: @"";
    STPFormTextField *textField = nil;
    switch (field) {
        case STPCardFieldTypeNumber:
            textField = self.numberField;
            break;
        case STPCardFieldTypeExpiration:
            textField = self.expirationField;
            break;
        case STPCardFieldTypeCVC:
            textField = self.cvcField;
            break;
        case STPCardFieldTypePostalCode:
            textField = self.postalCodeField;
            break;
    }
    textField.text = nonNilText;
}

- (CGFloat)numberFieldFullWidth {
    // Current longest possible pan is 16 digits which our standard sample fits
    if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid) {
        return [self widthForCardNumber:self.viewModel.cardNumber];
    }
    else {
        return MAX([self widthForCardNumber:self.viewModel.cardNumber],
                   [self widthForCardNumber:self.viewModel.defaultPlaceholder]);
    }
}

- (CGFloat)numberFieldCompressedWidth {

    NSString *cardNumber = self.cardNumber;
    if (cardNumber.length == 0) {
        cardNumber = self.viewModel.defaultPlaceholder;
    }

    STPCardBrand currentBrand = [STPCardValidator brandForNumber:cardNumber];
    NSArray<NSNumber *> *sortedCardNumberFormat = [[STPCardValidator cardNumberFormatForBrand:currentBrand] sortedArrayUsingSelector:@selector(unsignedIntegerValue)];
    NSUInteger fragmentLength = [STPCardValidator fragmentLengthForCardBrand:currentBrand];
    NSUInteger maxLength = MAX([[sortedCardNumberFormat lastObject] unsignedIntegerValue], fragmentLength);

    NSString *maxCompressedString = [@"" stringByPaddingToLength:maxLength withString:@"8" startingAtIndex:0];
    return [self widthForText:maxCompressedString];
}

- (CGFloat)cvcFieldWidth {
    if (self.focusedTextFieldForLayout == nil
        && [self.viewModel validationStateForField:STPCardFieldTypeCVC] == STPCardValidationStateValid) {
        // If we're not focused and have valid text, size exactly to what is entered
        return [self widthForText:self.viewModel.cvc];
    }
    else {
        // Otherwise size to fit our placeholder or what is likely to be the
        // largest possible string enterable (whichever is larger)
        NSInteger maxCvcLength = [STPCardValidator maxCVCLengthForCardBrand:self.viewModel.brand];
        NSString *longestCvc = @"888";
        if (maxCvcLength == 4) {
            longestCvc = @"8888";
        }

        return MAX([self widthForText:self.cvcField.placeholder], [self widthForText:longestCvc]);
    }
}

- (CGFloat)expirationFieldWidth {
    if (self.focusedTextFieldForLayout == nil
        && [self.viewModel validationStateForField:STPCardFieldTypeExpiration] == STPCardValidationStateValid) {
        // If we're not focused and have valid text, size exactly to what is entered
        return [self widthForText:self.viewModel.rawExpiration];
    }
    else {
        // Otherwise size to fit our placeholder or what is likely to be the
        // largest possible string enterable (whichever is larger)
        return MAX([self widthForText:self.expirationField.placeholder], [self widthForText:@"88/88"]);
    }
}

- (CGFloat)postalCodeFieldFullWidth {
    CGFloat compressedWidth = [self postalCodeFieldCompressedWidth];
    CGFloat currentTextWidth = [self widthForText:self.viewModel.postalCode];

    if (currentTextWidth <= compressedWidth) {
        return compressedWidth;
    }
    else if ([self.countryCode.uppercaseString isEqualToString:@"US"]) {
        // This format matches ZIP+4 which is currently disabled since it is
        // not used for billing, but could be useful for future shipping addr purposes
        return [self widthForText:@"88888-8888"];
    }
    else {
        // This format more closely matches the typical max UK/Canadian size which is our most common non-US market currently
        return [self widthForText:@"888 8888"];
    }
}

- (CGFloat)postalCodeFieldCompressedWidth {
    CGFloat maxTextWidth = 0;
    if ([self.countryCode.uppercaseString isEqualToString:@"US"]) {
        maxTextWidth = [self widthForText:@"88888"];
    }
    else {
        // This format more closely matches the typical max UK/Canadian size which is our most common non-US market currently
        maxTextWidth = [self widthForText:@"888 8888"];
    }

    CGFloat placeholderWidth = [self widthForText:[self defaultPostalFieldPlaceholderForCountryCode:self.countryCode]];
    return MAX(maxTextWidth, placeholderWidth);
}

- (CGSize)intrinsicContentSize {

    CGSize imageSize = self.brandImage.size;

    self.sizingField.text = self.viewModel.defaultPlaceholder;
    [self.sizingField sizeToFit];
    CGFloat textHeight = CGRectGetHeight(self.sizingField.frame);
    CGFloat imageHeight = imageSize.height + (STPPaymentCardTextFieldDefaultInsets);
    CGFloat height = stp_ceilCGFloat((MAX(MAX(imageHeight, textHeight), 44)));

    CGFloat width = (STPPaymentCardTextFieldDefaultInsets
                     + imageSize.width
                     + STPPaymentCardTextFieldDefaultInsets
                     + [self numberFieldFullWidth]
                     + STPPaymentCardTextFieldDefaultInsets
                     );

    width = stp_ceilCGFloat(width);

    return CGSizeMake(width, height);
}

typedef NS_ENUM(NSInteger, STPCardTextFieldState) {
    STPCardTextFieldStateVisible,
    STPCardTextFieldStateCompressed,
    STPCardTextFieldStateHidden,
};

- (CGFloat)minimumPaddingForViewsWithWidth:(CGFloat)width
                                       pan:(STPCardTextFieldState)panVisibility
                                    expiry:(STPCardTextFieldState)expiryVisibility
                                       cvc:(STPCardTextFieldState)cvcVisibility
                                    postal:(STPCardTextFieldState)postalVisibility {

    CGFloat requiredWidth = 0;
    CGFloat paddingsRequired = -1;

    if (panVisibility != STPCardTextFieldStateHidden) {
        paddingsRequired += 1;
        requiredWidth += (panVisibility == STPCardTextFieldStateCompressed) ? [self numberFieldCompressedWidth] : [self numberFieldFullWidth];
    }

    if (expiryVisibility != STPCardTextFieldStateHidden) {
        paddingsRequired += 1;
        requiredWidth += [self expirationFieldWidth];
    }

    if (cvcVisibility != STPCardTextFieldStateHidden) {
        paddingsRequired += 1;
        requiredWidth += [self cvcFieldWidth];
    }

    if (postalVisibility != STPCardTextFieldStateHidden
        && self.postalCodeEntryEnabled) {
        paddingsRequired += 1;
        requiredWidth += (postalVisibility == STPCardTextFieldStateCompressed) ? [self postalCodeFieldCompressedWidth] : [self postalCodeFieldFullWidth];
    }

    if (paddingsRequired > 0) {
        return stp_ceilCGFloat(((width - requiredWidth) / paddingsRequired));
    }
    else {
        return STPPaymentCardTextFieldMinimumPadding;
    }
}

- (CGRect)brandImageRectForBounds:(CGRect)bounds {
    return CGRectMake(STPPaymentCardTextFieldDefaultPadding, -1, self.brandImageView.image.size.width, bounds.size.height);
}

- (CGRect)fieldsRectForBounds:(CGRect)bounds {
    CGRect brandImageRect = [self brandImageRectForBounds:bounds];
    return CGRectMake(CGRectGetMaxX(brandImageRect), 0, CGRectGetWidth(bounds) - CGRectGetMaxX(brandImageRect), CGRectGetHeight(bounds));
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self recalculateSubviewLayout];
}

- (void)recalculateSubviewLayout {

    CGRect bounds = self.bounds;

    self.brandImageView.frame = [self brandImageRectForBounds:bounds];
    CGRect fieldsViewRect = [self fieldsRectForBounds:bounds];
    self.fieldsView.frame = fieldsViewRect;

    CGFloat availableFieldsWidth = CGRectGetWidth(fieldsViewRect) - (2 * STPPaymentCardTextFieldDefaultInsets);

    // These values are filled in via the if statements and then used
    // to do the proper layout at the end
    CGFloat fieldsHeight = CGRectGetHeight(fieldsViewRect);
    CGFloat hPadding = STPPaymentCardTextFieldDefaultPadding;
    __block STPCardTextFieldState panVisibility = STPCardTextFieldStateVisible;
    __block STPCardTextFieldState expiryVisibility = STPCardTextFieldStateVisible;
    __block STPCardTextFieldState cvcVisibility = STPCardTextFieldStateVisible;
    __block STPCardTextFieldState postalVisibility = self.postalCodeEntryEnabled ? STPCardTextFieldStateVisible : STPCardTextFieldStateHidden;

    CGFloat (^calculateMinimumPaddingWithLocalVars)(void) = ^CGFloat() {
        return [self minimumPaddingForViewsWithWidth:availableFieldsWidth
                                                 pan:panVisibility
                                              expiry:expiryVisibility
                                                 cvc:cvcVisibility
                                              postal:postalVisibility];
    };

    hPadding = calculateMinimumPaddingWithLocalVars();

    if (hPadding >= STPPaymentCardTextFieldMinimumPadding) {
        // Can just render everything at full size
        // Do Nothing
    }
    else {
        // Need to do selective view compression/hiding

        if (self.focusedTextFieldForLayout == nil) {
            /*
             No field is currently being edited -
             
             Render all fields visible:
             Show compressed PAN, visible CVC and expiry, fill remaining space 
             with postal if necessary

             The most common way to be in this state is the user finished entry
             and has moved on to another field (so we want to show summary)
             but possibly some fields are invalid
             */
            while (hPadding < STPPaymentCardTextFieldMinimumPadding) {
                // Try hiding things in this order
                if (panVisibility == STPCardTextFieldStateVisible) {
                    panVisibility = STPCardTextFieldStateCompressed;
                }
                else if (postalVisibility == STPCardTextFieldStateVisible) {
                    postalVisibility = STPCardTextFieldStateCompressed;
                }
                else {
                    // Can't hide anything else, set to minimum and stop
                    hPadding = STPPaymentCardTextFieldMinimumPadding;
                    break;
                }
                hPadding = calculateMinimumPaddingWithLocalVars();
            }
        }
        else {
            switch ((STPCardFieldType)self.focusedTextFieldForLayout.integerValue) {
                case STPCardFieldTypeNumber: {
                    /*
                     The user is entering PAN
                     
                     It must be fully visible. Everything else is optional
                     */

                    while (hPadding < STPPaymentCardTextFieldMinimumPadding) {
                        if (postalVisibility == STPCardTextFieldStateVisible) {
                            postalVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (postalVisibility == STPCardTextFieldStateCompressed) {
                            postalVisibility = STPCardTextFieldStateHidden;
                        }
                        else if (cvcVisibility == STPCardTextFieldStateVisible) {
                            cvcVisibility = STPCardTextFieldStateHidden;
                        }
                        else if (expiryVisibility == STPCardTextFieldStateVisible) {
                            expiryVisibility = STPCardTextFieldStateHidden;
                        }
                        else {
                            hPadding = STPPaymentCardTextFieldMinimumPadding;
                            break;
                        }
                        hPadding = calculateMinimumPaddingWithLocalVars();
                    }
                }
                    break;
                case STPCardFieldTypeExpiration: {
                    /*
                     The user is entering expiration date

                     It must be fully visible, and the next and previous fields
                     must be visible so they can be tapped over to
                     */
                    while (hPadding < STPPaymentCardTextFieldMinimumPadding) {
                        if (panVisibility == STPCardTextFieldStateVisible) {
                            panVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (postalVisibility == STPCardTextFieldStateVisible) {
                            postalVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (postalVisibility == STPCardTextFieldStateCompressed) {
                            postalVisibility = STPCardTextFieldStateHidden;
                        }
                        else {
                            hPadding = STPPaymentCardTextFieldMinimumPadding;
                            break;
                        }
                        hPadding = calculateMinimumPaddingWithLocalVars();
                    }
                }
                    break;

                case STPCardFieldTypeCVC: {
                    /*
                     The user is entering CVC

                     It must be fully visible, and the next and previous fields
                     must be visible so they can be tapped over to (although
                     there might not be a next field)
                     */
                    while (hPadding < STPPaymentCardTextFieldMinimumPadding) {
                        if (panVisibility == STPCardTextFieldStateVisible) {
                            panVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (postalVisibility == STPCardTextFieldStateVisible) {
                            postalVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (panVisibility == STPCardTextFieldStateCompressed) {
                            panVisibility = STPCardTextFieldStateHidden;
                        }
                        else {
                            hPadding = STPPaymentCardTextFieldMinimumPadding;
                            break;
                        }
                        hPadding = calculateMinimumPaddingWithLocalVars();
                    }
                }
                    break;
                case STPCardFieldTypePostalCode: {
                    /*
                     The user is entering postal code

                     It must be fully visible, and the previous field must
                     be visible
                     */
                    while (hPadding < STPPaymentCardTextFieldMinimumPadding) {
                        if (panVisibility == STPCardTextFieldStateVisible) {
                            panVisibility = STPCardTextFieldStateCompressed;
                        }
                        else if (panVisibility == STPCardTextFieldStateCompressed) {
                            panVisibility = STPCardTextFieldStateHidden;
                        }
                        else if (expiryVisibility == STPCardTextFieldStateVisible) {
                            expiryVisibility = STPCardTextFieldStateHidden;
                        }
                        else {
                            hPadding = STPPaymentCardTextFieldMinimumPadding;
                            break;
                        }
                        hPadding = calculateMinimumPaddingWithLocalVars();
                    }
                }
                    break;
            }
        }
    }

    // -- Do layout here --
    CGFloat xOffset = STPPaymentCardTextFieldDefaultInsets;
    CGFloat width = 0;

    // Make all fields actually slightly wider than needed so that when the
    // cursor is at the end position the contents aren't clipped off to the left side
    CGFloat additionalWidth = [self widthForText:@"8"];

    if (panVisibility == STPCardTextFieldStateCompressed) {
        // Need to lower xOffset so pan is partially off-screen

        BOOL hasEnteredCardNumber = self.cardNumber.length > 0;
        NSString *compressedCardNumber = self.viewModel.compressedCardNumber;
        NSString *cardNumberToHide = [(hasEnteredCardNumber ? self.cardNumber : self.viewModel.defaultPlaceholder) stp_stringByRemovingSuffix:compressedCardNumber];

        if (cardNumberToHide.length > 0) {
            width = hasEnteredCardNumber ? [self widthForCardNumber:self.cardNumber] : [self numberFieldFullWidth];

            CGFloat hiddenWidth = [self widthForCardNumber:cardNumberToHide];
            xOffset -= hiddenWidth;
            UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(hiddenWidth,
                                                                        0,
                                                                        (width - hiddenWidth),
                                                                        fieldsHeight)];
            maskView.backgroundColor = [UIColor blackColor];
            maskView.opaque = YES;
            maskView.userInteractionEnabled = NO;
            [UIView performWithoutAnimation:^{
                self.numberField.maskView = maskView;
            }];
        } else {
            width = [self numberFieldCompressedWidth];
            [UIView performWithoutAnimation:^{
                self.numberField.maskView = nil;
            }];
        }
    }
    else {
        width = [self numberFieldFullWidth];
        [UIView performWithoutAnimation:^{
            self.numberField.maskView = nil;
        }];

        if (panVisibility == STPCardTextFieldStateHidden) {
            // Need to lower xOffset so pan is fully off screen
            xOffset = xOffset - width - hPadding;
        }
    }

    self.numberField.frame = CGRectMake(xOffset, 0, width + additionalWidth, fieldsHeight);
    xOffset += width + hPadding;

    width = [self expirationFieldWidth];
    self.expirationField.frame = CGRectMake(xOffset, 0, width + additionalWidth, fieldsHeight);
    xOffset += width + hPadding;

    width = [self cvcFieldWidth];
    self.cvcField.frame = CGRectMake(xOffset, 0, width + additionalWidth, fieldsHeight);
    xOffset += width + hPadding;

    if (self.postalCodeEntryEnabled) {
        width = self.fieldsView.frame.size.width - xOffset - STPPaymentCardTextFieldDefaultInsets;
        self.postalCodeField.frame = CGRectMake(xOffset, 0, width + additionalWidth, fieldsHeight);
    }

    void (^updateFieldVisibility)(STPFormTextField *, STPCardTextFieldState) = ^(STPFormTextField *field, STPCardTextFieldState fieldState) {
        if (fieldState == STPCardTextFieldStateHidden) {
            field.alpha = 0.0f;
            field.isAccessibilityElement = NO;
        } else {
            field.alpha = 1.0f;
            field.isAccessibilityElement = YES;
        }
    };

    updateFieldVisibility(self.numberField, panVisibility);
    updateFieldVisibility(self.expirationField, expiryVisibility);
    updateFieldVisibility(self.cvcField, cvcVisibility);
    updateFieldVisibility(self.postalCodeField, self.postalCodeEntryEnabled ? postalVisibility :  STPCardTextFieldStateHidden);
}

#pragma mark - private helper methods

- (STPFormTextField *)buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    // setCountryCode: updates the postalCodeField keyboardType, this is safe
    if (@available(iOS 10, *)) {
        textField.keyboardType = UIKeyboardTypeASCIICapableNumberPad;
    } else {
        textField.keyboardType = UIKeyboardTypePhonePad;
    }
    textField.textAlignment = NSTextAlignmentLeft;
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.formDelegate = self;
    textField.validText = true;
    return textField;
}

typedef void (^STPLayoutAnimationCompletionBlock)(BOOL completed);
- (void)layoutViewsToFocusField:(NSNumber *)focusedField
                       animated:(BOOL)animated
                     completion:(STPLayoutAnimationCompletionBlock)completion {

    NSNumber *fieldtoFocus = focusedField;

    if (fieldtoFocus == nil
        && ![self.focusedTextFieldForLayout isEqualToNumber:@(STPCardFieldTypeNumber)]
        && ([self.viewModel validationStateForField:STPCardFieldTypeNumber] != STPCardValidationStateValid)) {
        fieldtoFocus = @(STPCardFieldTypeNumber);
        [self.numberField becomeFirstResponder];
    }

    if ((fieldtoFocus == nil && self.focusedTextFieldForLayout == nil)
        || (fieldtoFocus != nil && [self.focusedTextFieldForLayout isEqualToNumber:fieldtoFocus])
        ) {
        if (completion) {
            completion(YES);
        }
        return;
    }

    self.focusedTextFieldForLayout = fieldtoFocus;

    void (^animations)(void) = ^void() {
        [self recalculateSubviewLayout];
    };

    if (animated) {
        NSTimeInterval duration = animated * 0.3;
        [UIView animateWithDuration:duration
                              delay:0
             usingSpringWithDamping:0.85f
              initialSpringVelocity:0
                            options:0
                         animations:animations
                         completion:completion];
    }
    else {
        animations();
    }
}

- (CGFloat)widthForAttributedText:(NSAttributedString *)attributedText {
    // UITextField doesn't seem to size correctly here for unknown reasons
    // But UILabel reliably calculates size correctly using this method
    self.sizingLabel.attributedText = attributedText;
    [self.sizingLabel sizeToFit];
    return stp_ceilCGFloat((CGRectGetWidth(self.sizingLabel.bounds)));

}

- (CGFloat)widthForText:(NSString *)text {
    if (text.length == 0) {
        return 0;
    }

    NSNumber *cachedValue = self.textToWidthCache[text];
    if (cachedValue == nil) {
        self.sizingField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorNone;
        [self.sizingField setText:STPNonLocalizedString(text)];
        cachedValue = @([self widthForAttributedText:self.sizingField.attributedText]);
        self.textToWidthCache[text] = cachedValue;
    }
    return (CGFloat)[cachedValue doubleValue];
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    if (cardNumber.length == 0) {
        return 0;
    }

    NSNumber *cachedValue = self.numberToWidthCache[cardNumber];
    if (cachedValue == nil) {
        self.sizingField.autoFormattingBehavior = STPFormTextFieldAutoFormattingBehaviorCardNumbers;
        [self.sizingField setText:cardNumber];
        cachedValue = @([self widthForAttributedText:self.sizingField.attributedText]);
        self.numberToWidthCache[cardNumber] = cachedValue;
    }
    return (CGFloat)[cachedValue doubleValue];
}

#pragma mark STPFormTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    if (previous.hasText) {
        [previous deleteBackward];
    }
}

- (NSAttributedString *)formTextField:(STPFormTextField *)formTextField
   modifyIncomingTextChange:(NSAttributedString *)input {
    STPCardFieldType fieldType = formTextField.tag;
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            self.viewModel.cardNumber = input.string;
            [self setNeedsLayout];
            break;
        case STPCardFieldTypeExpiration:
            self.viewModel.rawExpiration = input.string;
            break;
        case STPCardFieldTypeCVC:
            self.viewModel.cvc = input.string;
            break;
        case STPCardFieldTypePostalCode:
            self.viewModel.postalCode = input.string;
            [self setNeedsLayout];
            break;
    }
    
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            return [[NSAttributedString alloc] initWithString:self.viewModel.cardNumber
                                                   attributes:self.numberField.defaultTextAttributes];
        case STPCardFieldTypeExpiration:
            return [[NSAttributedString alloc] initWithString:self.viewModel.rawExpiration
                                                   attributes:self.expirationField.defaultTextAttributes];
        case STPCardFieldTypeCVC:
            return [[NSAttributedString alloc] initWithString:self.viewModel.cvc
                                                   attributes:self.cvcField.defaultTextAttributes];
        case STPCardFieldTypePostalCode:
            return [[NSAttributedString alloc] initWithString:self.viewModel.postalCode
                                                   attributes:self.cvcField.defaultTextAttributes];
    }
}

- (void)formTextFieldTextDidChange:(STPFormTextField *)formTextField {
    STPCardFieldType fieldType = formTextField.tag;
    if (fieldType == STPCardFieldTypeNumber) {
        [self updateImageForFieldType:fieldType];
        [self updateCVCPlaceholder];
    }
    
    STPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    formTextField.validText = YES;
    switch (state) {
        case STPCardValidationStateInvalid:
            formTextField.validText = NO;
            break;
        case STPCardValidationStateIncomplete:
            break;
        case STPCardValidationStateValid: {
            if (fieldType == STPCardFieldTypeCVC) {
                /*
                 Even though any CVC longer than the min required CVC length 
                 is valid, we don't want to forward on to the next field
                 unless it is actually >= the max cvc length (otherwise when
                 postal code is showing, you can't easily enter CVCs longer than
                 the minimum.
                 */
                NSString *sanitizedCvc = [STPCardValidator sanitizedNumericStringForString:formTextField.text];
                if (sanitizedCvc.length < [STPCardValidator maxCVCLengthForCardBrand:self.viewModel.brand]) {
                    break;
                }
            }

            // This is a no-op if this is the last field & they're all valid
            [[self nextFirstResponderField] becomeFirstResponder];
            break;
        }
    }

    [self onChange];
}


typedef NS_ENUM(NSInteger, STPFieldEditingTransitionCallSite) {
    STPFieldEditingTransitionCallSiteShouldBegin,
    STPFieldEditingTransitionCallSiteShouldEnd,
    STPFieldEditingTransitionCallSiteDidBegin,
    STPFieldEditingTransitionCallSiteDidEnd,
};

// Explanation of the logic here is with the definition of these properties
// at the top of this file
- (BOOL)getAndUpdateSubviewEditingTransitionStateFromCall:(STPFieldEditingTransitionCallSite)sendingMethod {
    BOOL stateToReturn;
    switch (sendingMethod) {
        case STPFieldEditingTransitionCallSiteShouldBegin:
            self.receivedUnmatchedShouldBeginEditing = YES;
            if (self.receivedUnmatchedShouldEndEditing) {
                self.isMidSubviewEditingTransitionInternal = YES;
            }
            stateToReturn = self.isMidSubviewEditingTransitionInternal;
            break;
        case STPFieldEditingTransitionCallSiteShouldEnd:
            self.receivedUnmatchedShouldEndEditing = YES;
            if (self.receivedUnmatchedShouldBeginEditing) {
                self.isMidSubviewEditingTransitionInternal = YES;
            }
            stateToReturn = self.isMidSubviewEditingTransitionInternal;
            break;
        case STPFieldEditingTransitionCallSiteDidBegin:
            stateToReturn = self.isMidSubviewEditingTransitionInternal;
            self.receivedUnmatchedShouldBeginEditing = NO;

            if (self.receivedUnmatchedShouldEndEditing == NO) {
                self.isMidSubviewEditingTransitionInternal = NO;
            }
            break;
        case STPFieldEditingTransitionCallSiteDidEnd:
            stateToReturn = self.isMidSubviewEditingTransitionInternal;
            self.receivedUnmatchedShouldEndEditing = NO;

            if (self.receivedUnmatchedShouldBeginEditing == NO) {
                self.isMidSubviewEditingTransitionInternal = NO;
            }
            break;
    }

    return stateToReturn;
}


- (void)resetSubviewEditingTransitionState {
    self.isMidSubviewEditingTransitionInternal = NO;
    self.receivedUnmatchedShouldBeginEditing = NO;
    self.receivedUnmatchedShouldEndEditing = NO;
}

- (BOOL)textFieldShouldBeginEditing:(__unused UITextField *)textField {
    [self getAndUpdateSubviewEditingTransitionStateFromCall:STPFieldEditingTransitionCallSiteShouldBegin];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    BOOL isMidSubviewEditingTransition = [self getAndUpdateSubviewEditingTransitionStateFromCall:STPFieldEditingTransitionCallSiteDidBegin];

    [self layoutViewsToFocusField:@(textField.tag)
                         animated:YES
                       completion:nil];

    if (!isMidSubviewEditingTransition) {
        if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditing:)]) {
            [self.delegate paymentCardTextFieldDidBeginEditing:self];
        }
    }

    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            ((STPFormTextField *)textField).validText = YES;
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingNumber:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingNumber:self];
            }
            break;
        case STPCardFieldTypeCVC:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingCVC:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingCVC:self];
            }
            break;
        case STPCardFieldTypeExpiration:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingExpiration:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingExpiration:self];
            }
            break;
        case STPCardFieldTypePostalCode:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidBeginEditingPostalCode:)]) {
                [self.delegate paymentCardTextFieldDidBeginEditingPostalCode:self];
            }
            break;
    }
    [self updateImageForFieldType:textField.tag];
}

- (BOOL)textFieldShouldEndEditing:(__unused UITextField *)textField {
    [self getAndUpdateSubviewEditingTransitionStateFromCall:STPFieldEditingTransitionCallSiteShouldEnd];
    [self updateImageForFieldType:STPCardFieldTypeNumber];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    BOOL isMidSubviewEditingTransition = [self getAndUpdateSubviewEditingTransitionStateFromCall:STPFieldEditingTransitionCallSiteDidEnd];

    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateIncomplete) {
                ((STPFormTextField *)textField).validText = NO;
            }
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingNumber:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingNumber:self];
            }
            break;
        case STPCardFieldTypeCVC:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingCVC:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingCVC:self];
            }
            break;
        case STPCardFieldTypeExpiration:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingExpiration:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingExpiration:self];
            }
            break;
        case STPCardFieldTypePostalCode:
            if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditingPostalCode:)]) {
                [self.delegate paymentCardTextFieldDidEndEditingPostalCode:self];
            }
            break;
    }

    if (!isMidSubviewEditingTransition) {
        [self layoutViewsToFocusField:nil
                             animated:YES
                           completion:nil];
        [self updateImageForFieldType:STPCardFieldTypeNumber];
        if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidEndEditing:)]) {
            [self.delegate paymentCardTextFieldDidEndEditing:self];
        }
    }
}

- (UIImage *)brandImage {
    STPCardFieldType fieldType = STPCardFieldTypeNumber;
    if (self.currentFirstResponderField) {
        fieldType = self.currentFirstResponderField.tag;
    }
    STPCardValidationState validationState = [self.viewModel validationStateForField:fieldType];
    return [self brandImageForFieldType:fieldType validationState:validationState];
}

+ (UIImage *)cvcImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPImageLibrary cvcImageForCardBrand:cardBrand];
}

+ (UIImage *)brandImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPImageLibrary brandImageForCardBrand:cardBrand];
}

+ (UIImage *)errorImageForCardBrand:(STPCardBrand)cardBrand {
    return [STPImageLibrary errorImageForCardBrand:cardBrand];
}

- (UIImage *)brandImageForFieldType:(STPCardFieldType)fieldType validationState:(STPCardValidationState)validationState {
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            if (validationState == STPCardValidationStateInvalid) {
                return [self.class errorImageForCardBrand:self.viewModel.brand];
            } else {
                return [self.class brandImageForCardBrand:self.viewModel.brand];
            }
        case STPCardFieldTypeCVC:
            return [self.class cvcImageForCardBrand:self.viewModel.brand];
        case STPCardFieldTypeExpiration:
            return [self.class brandImageForCardBrand:self.viewModel.brand];
        case STPCardFieldTypePostalCode:
            return [self.class brandImageForCardBrand:self.viewModel.brand];
    }
}

- (UIViewAnimationOptions)brandImageAnimationOptionsForNewType:(STPCardFieldType)newType
                                                      newBrand:(STPCardBrand)newBrand
                                                       oldType:(STPCardFieldType)oldType
                                                      oldBrand:(STPCardBrand)oldBrand {

    if (newType == STPCardFieldTypeCVC
        && oldType != STPCardFieldTypeCVC) {
        // Transitioning to show CVC

        if (newBrand != STPCardBrandAmex) {
            // CVC is on the back
            return (UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromRight);
        }
    }
    else if (newType != STPCardFieldTypeCVC
             && oldType == STPCardFieldTypeCVC) {
        // Transitioning to stop showing CVC

        if (oldBrand != STPCardBrandAmex) {
            // CVC was on the back
            return (UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionFlipFromLeft);
        }
    }

    // All other cases just cross dissolve
    return (UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve);

}

- (void)updateImageForFieldType:(STPCardFieldType)fieldType {
    STPCardValidationState validationState = [self.viewModel validationStateForField:fieldType];
    UIImage *image = [self brandImageForFieldType:fieldType validationState:validationState];
    if (![image isEqual:self.brandImageView.image]) {

        STPCardBrand newBrand = self.viewModel.brand;
        UIViewAnimationOptions imageAnimationOptions = [self brandImageAnimationOptionsForNewType:fieldType
                                                                                         newBrand:newBrand
                                                                                          oldType:self.currentBrandImageFieldType
                                                                                         oldBrand:self.currentBrandImageBrand];

        self.currentBrandImageFieldType = fieldType;
        self.currentBrandImageBrand = newBrand;

        [UIView transitionWithView:self.brandImageView
                          duration:0.2
                           options:imageAnimationOptions
                        animations:^{
                            self.brandImageView.image = image;
                        }
                        completion:nil];
    }
}

- (NSString *)defaultCVCPlaceholder {
    if (self.viewModel.brand == STPCardBrandAmex) {
        return STPNonLocalizedString(@"CVV");
    } else {
        return STPNonLocalizedString(@"CVC");
    }
}

- (void)updateCVCPlaceholder {
    if (self.cvcPlaceholder) {
        self.cvcField.placeholder = self.cvcPlaceholder;
        self.cvcField.accessibilityLabel = self.cvcPlaceholder;
    } else {
        self.cvcField.placeholder = [self defaultCVCPlaceholder];
        self.cvcField.accessibilityLabel = [self defaultCVCPlaceholder];
    }
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark UIKeyInput

- (BOOL)hasText {
    return self.numberField.hasText || self.expirationField.hasText || self.cvcField.hasText;
}

- (void)insertText:(NSString *)text {
    [self.currentFirstResponderField insertText:text];
}

- (void)deleteBackward {
    [self.currentFirstResponderField deleteBackward];
}

+ (NSSet<NSString *> *)keyPathsForValuesAffectingIsValid {
    return [NSSet setWithArray:@[
                                 [NSString stringWithFormat:@"%@.%@",
                                  NSStringFromSelector(@selector(viewModel)),
                                  NSStringFromSelector(@selector(valid))],
                                 ]];
}

@end
