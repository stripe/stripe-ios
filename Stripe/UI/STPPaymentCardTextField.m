//
//  STPPaymentCardTextField.m
//  Stripe
//
//  Created by Jack Flintermann on 7/16/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Stripe.h"
#import "STPPaymentCardTextField.h"
#import "STPPaymentCardTextFieldViewModel.h"
#import "STPFormTextField.h"
#import "STPCardValidator.h"

#define FAUXPAS_IGNORED_IN_METHOD(...)

@interface STPPaymentCardTextField()<STPFormTextFieldDelegate>

@property(nonatomic, readwrite, strong)STPFormTextField *sizingField;

@property(nonatomic, readwrite, weak)UIImageView *brandImageView;
@property(nonatomic, readwrite, weak)UIView *fieldsView;

@property(nonatomic, readwrite, weak)STPFormTextField *numberField;

@property(nonatomic, readwrite, weak)STPFormTextField *expirationField;

@property(nonatomic, readwrite, weak)STPFormTextField *cvcField;

@property(nonatomic, readwrite, strong)STPPaymentCardTextFieldViewModel *viewModel;

@property(nonatomic, readwrite, weak)UITextField *selectedField;

@property(nonatomic, assign)BOOL numberFieldShrunk;

@end

@implementation STPPaymentCardTextField

@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize textErrorColor = _textErrorColor;
@synthesize placeholderColor = _placeholderColor;
@dynamic enabled;

CGFloat const STPPaymentCardTextFieldDefaultPadding = 10;

#if CGFLOAT_IS_DOUBLE
#define stp_roundCGFloat(x) round(x)
#else
#define stp_roundCGFloat(x) roundf(x)
#endif

#pragma mark initializers

- (id)initWithCoder:(NSCoder *)aDecoder {
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
    
    self.borderColor = [self.class placeholderGrayColor];
    self.cornerRadius = 5.0f;
    self.borderWidth = 1.0f;

    self.clipsToBounds = YES;
    
    _viewModel = [STPPaymentCardTextFieldViewModel new];
    _sizingField = [self buildTextField];
    
    UIImageView *brandImageView = [[UIImageView alloc] initWithImage:_viewModel.brandImage];
    brandImageView.contentMode = UIViewContentModeCenter;
    brandImageView.backgroundColor = [UIColor clearColor];
    if ([brandImageView respondsToSelector:@selector(setTintColor:)]) {
        brandImageView.tintColor = self.placeholderColor;
    }
    self.brandImageView = brandImageView;
    
    STPFormTextField *numberField = [self buildTextField];
    numberField.formatsCardNumbers = YES;
    numberField.tag = STPCardFieldTypeNumber;
    self.numberField = numberField;
    self.numberPlaceholder = [self.viewModel defaultPlaceholder];

    STPFormTextField *expirationField = [self buildTextField];
    expirationField.tag = STPCardFieldTypeExpiration;
    expirationField.alpha = 0;
    self.expirationField = expirationField;
    self.expirationPlaceholder = @"MM/YY";
        
    STPFormTextField *cvcField = [self buildTextField];
    cvcField.tag = STPCardFieldTypeCVC;
    cvcField.alpha = 0;
    self.cvcField = cvcField;
    self.cvcPlaceholder = @"CVC";
    
    UIView *fieldsView = [[UIView alloc] init];
    fieldsView.clipsToBounds = YES;
    fieldsView.backgroundColor = [UIColor clearColor];
    self.fieldsView = fieldsView;
    
    [self addSubview:self.fieldsView];
    [self.fieldsView addSubview:cvcField];
    [self.fieldsView addSubview:expirationField];
    [self.fieldsView addSubview:numberField];
    [self addSubview:brandImageView];
}

- (STPPaymentCardTextFieldViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [STPPaymentCardTextFieldViewModel new];
    }
    return _viewModel;
}

#pragma mark appearance properties

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
    
    if ([self.brandImageView respondsToSelector:@selector(setTintColor:)]) {
        self.brandImageView.tintColor = placeholderColor;
    }
    
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

- (void)setBorderColor:(UIColor * __nullable)borderColor {
    self.layer.borderColor = [[borderColor copy] CGColor];
}

- (UIColor * __nullable)borderColor {
    return [[UIColor alloc] initWithCGColor:self.layer.borderColor];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    self.layer.cornerRadius = cornerRadius;
}

- (CGFloat)cornerRadius {
    return self.layer.cornerRadius;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    self.layer.borderWidth = borderWidth;
}

- (CGFloat)borderWidth {
    return self.layer.borderWidth;
}

- (void)setKeyboardAppearance:(UIKeyboardAppearance)keyboardAppearance {
    _keyboardAppearance = keyboardAppearance;
    for (STPFormTextField *field in [self allFields]) {
        field.keyboardAppearance = keyboardAppearance;
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
    return [self.selectedField isFirstResponder];
}

- (BOOL)canBecomeFirstResponder {
    return [[self firstResponderField] canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [[self firstResponderField] becomeFirstResponder];
}

- (STPFormTextField *)firstResponderField {

    if ([self.viewModel validationStateForField:STPCardFieldTypeNumber] != STPCardValidationStateValid) {
        return self.numberField;
    } else if ([self.viewModel validationStateForField:STPCardFieldTypeExpiration] != STPCardValidationStateValid) {
        return self.expirationField;
    } else {
        return self.cvcField;
    }
}

- (BOOL)canResignFirstResponder {
    return [self.selectedField canResignFirstResponder];
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    BOOL success = [self.selectedField resignFirstResponder];
    [self setNumberFieldShrunk:[self shouldShrinkNumberField] animated:YES completion:nil];
    return success;
}

- (BOOL)selectNextField {
    return [[self nextField] becomeFirstResponder];
}

- (BOOL)selectPreviousField {
    return [[self previousField] becomeFirstResponder];
}

- (STPFormTextField *)nextField {
    if (self.selectedField == self.numberField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.cvcField;
    }
    return nil;
}

- (STPFormTextField *)previousField {
    if (self.selectedField == self.cvcField) {
        return self.expirationField;
    } else if (self.selectedField == self.expirationField) {
        return self.numberField;
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
    __weak id weakself = self;
    [self setNumberFieldShrunk:NO animated:YES completion:^(__unused BOOL completed){
        __strong id strongself = weakself;
        if ([strongself isFirstResponder]) {
            [[strongself numberField] becomeFirstResponder];
        }
    }];
}

- (BOOL)isValid {
    return [self.viewModel isValid];
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

- (NSString *)cvc {
    return self.viewModel.cvc;
}

- (STPCardParams *)card {
    if (!self.isValid) { return nil; }
    
    STPCardParams *c = [[STPCardParams alloc] init];
    c.number = self.cardNumber;
    c.expMonth = self.expirationMonth;
    c.expYear = self.expirationYear;
    c.cvc = self.cvc;
    return c;
}

- (CGSize)intrinsicContentSize {
    
    CGSize imageSize = self.viewModel.brandImage.size;
    
    self.sizingField.text = self.viewModel.defaultPlaceholder;
    CGFloat textHeight = [self.sizingField measureTextSize].height;
    CGFloat imageHeight = imageSize.height + (STPPaymentCardTextFieldDefaultPadding * 2);
    CGFloat height = stp_roundCGFloat((MAX(MAX(imageHeight, textHeight), 44)));
    
    CGFloat width = stp_roundCGFloat([self widthForCardNumber:self.viewModel.defaultPlaceholder] + imageSize.width + (STPPaymentCardTextFieldDefaultPadding * 3));
    
    return CGSizeMake(width, height);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.brandImageView.frame = CGRectMake(STPPaymentCardTextFieldDefaultPadding, 2, self.brandImageView.image.size.width, self.frame.size.height - 2);
    self.fieldsView.frame = CGRectMake(CGRectGetMaxX(self.brandImageView.frame), 0, self.bounds.size.width - CGRectGetMaxX(self.brandImageView.frame), self.frame.size.height);
    
    CGFloat placeholderWidth = [self widthForCardNumber:self.numberField.placeholder] - 4;
    CGFloat numberWidth = [self widthForCardNumber:self.viewModel.defaultPlaceholder] - 4;
    CGFloat numberFieldWidth = MAX(placeholderWidth, numberWidth);
    CGFloat nonFragmentWidth = [self widthForCardNumber:[self.viewModel numberWithoutLastDigits]] - 8;
    CGFloat numberFieldX = self.numberFieldShrunk ? STPPaymentCardTextFieldDefaultPadding - nonFragmentWidth : 8;
    self.numberField.frame = CGRectMake(numberFieldX, 0, numberFieldWidth, self.frame.size.height);
    
    CGFloat cvcWidth = MAX([self widthForText:self.cvcField.placeholder], [self widthForText:@"8888"]);
    CGFloat cvcX = self.numberFieldShrunk ?
        self.fieldsView.bounds.size.width - cvcWidth - STPPaymentCardTextFieldDefaultPadding / 2  :
        self.fieldsView.bounds.size.width;
    self.cvcField.frame = CGRectMake(cvcX, 0, cvcWidth, self.frame.size.height);
    
    CGFloat expirationWidth = MAX([self widthForText:self.expirationField.placeholder], [self widthForText:@"88/88"]);
    CGFloat expirationX = (CGRectGetMaxX(self.numberField.frame) + CGRectGetMinX(self.cvcField.frame) - expirationWidth) / 2;
    self.expirationField.frame = CGRectMake(expirationX, 0, expirationWidth, self.frame.size.height);
    
}

#pragma mark - private helper methods

- (STPFormTextField *)buildTextField {
    STPFormTextField *textField = [[STPFormTextField alloc] initWithFrame:CGRectZero];
    textField.backgroundColor = [UIColor clearColor];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.font = self.font;
    textField.defaultColor = self.textColor;
    textField.errorColor = self.textErrorColor;
    textField.placeholderColor = self.placeholderColor;
    textField.formDelegate = self;
    return textField;
}

- (NSArray *)allFields {
    return @[self.numberField, self.expirationField, self.cvcField];
}

typedef void (^STPNumberShrunkCompletionBlock)(BOOL completed);
- (void)setNumberFieldShrunk:(BOOL)shrunk animated:(BOOL)animated
                  completion:(STPNumberShrunkCompletionBlock)completion {
    
    if (_numberFieldShrunk == shrunk) {
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    _numberFieldShrunk = shrunk;
    void (^animations)() = ^void() {
        for (UIView *view in @[self.expirationField, self.cvcField]) {
            view.alpha = 1.0f * shrunk;
        }
        [self layoutSubviews];
    };
    
    FAUXPAS_IGNORED_IN_METHOD(APIAvailability);
    NSTimeInterval duration = animated * 0.3;
    if ([UIView respondsToSelector:@selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)]) {
        [UIView animateWithDuration:duration
                              delay:0
             usingSpringWithDamping:0.85f
              initialSpringVelocity:0
                            options:0
                         animations:animations
                         completion:completion];
    } else {
        [UIView animateWithDuration:duration
                         animations:animations
                         completion:completion];
    }
}

- (BOOL)shouldShrinkNumberField {
    return [self.viewModel validationStateForField:STPCardFieldTypeNumber] == STPCardValidationStateValid;
}

- (CGFloat)widthForText:(NSString *)text {
    self.sizingField.formatsCardNumbers = NO;
    [self.sizingField setText:text];
    return [self.sizingField measureTextSize].width + 8;
}

- (CGFloat)widthForTextWithLength:(NSUInteger)length {
    NSString *text = [@"" stringByPaddingToLength:length withString:@"M" startingAtIndex:0];
    return [self widthForText:text];
}

- (CGFloat)widthForCardNumber:(NSString *)cardNumber {
    self.sizingField.formatsCardNumbers = YES;
    [self.sizingField setText:cardNumber];
    return [self.sizingField measureTextSize].width + 15;
}

#pragma mark STPPaymentTextFieldDelegate

- (void)formTextFieldDidBackspaceOnEmpty:(__unused STPFormTextField *)formTextField {
    STPFormTextField *previous = [self previousField];
    [previous becomeFirstResponder];
    [previous deleteBackward];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.selectedField = (STPFormTextField *)textField;
    switch ((STPCardFieldType)textField.tag) {
        case STPCardFieldTypeNumber:
            [self setNumberFieldShrunk:NO animated:YES completion:nil];
            break;
            
        default:
            [self setNumberFieldShrunk:YES animated:YES completion:nil];
            break;
    }
    [self updateImageForFieldType:textField.tag];
}

- (void)textFieldDidEndEditing:(__unused UITextField *)textField {
    self.selectedField = nil;
}

- (BOOL)textField:(STPFormTextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    BOOL deletingLastCharacter = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    if (deletingLastCharacter && [textField.text hasSuffix:@"/"] && range.location > 0) {
        range.location -= 1;
        range.length += 1;
    }
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    STPCardFieldType fieldType = textField.tag;
    switch (fieldType) {
        case STPCardFieldTypeNumber:
            self.viewModel.cardNumber = newText;
            textField.text = self.viewModel.cardNumber;
            break;
        case STPCardFieldTypeExpiration: {
            self.viewModel.rawExpiration = newText;
            textField.text = self.viewModel.rawExpiration;
            break;
        }
        case STPCardFieldTypeCVC:
            self.viewModel.cvc = newText;
            textField.text = self.viewModel.cvc;
            break;
    }
    
    [self updateImageForFieldType:fieldType];

    STPCardValidationState state = [self.viewModel validationStateForField:fieldType];
    textField.validText = YES;
    switch (state) {
        case STPCardValidationStateInvalid:
            textField.validText = NO;
            break;
        case STPCardValidationStateIncomplete:
            break;
        case STPCardValidationStateValid: {
            [self selectNextField];
            break;
        }
    }
    [self onChange];

    return NO;
}

- (void)updateImageForFieldType:(STPCardFieldType)fieldType {
    UIImage *image = fieldType == STPCardFieldTypeCVC ? self.viewModel.cvcImage : self.viewModel.brandImage;
    if (image != self.brandImageView.image) {
        self.brandImageView.image = image;
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.2f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        
        [self.brandImageView.layer addAnimation:transition forKey:nil];
    }
}

- (void)onChange {
    if ([self.delegate respondsToSelector:@selector(paymentCardTextFieldDidChange:)]) {
        [self.delegate paymentCardTextFieldDidChange:self];
    }
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

@implementation PTKCard
@end

@interface PTKView()
@property(nonatomic, weak)id<PTKViewDelegate>internalDelegate;
@end

@implementation PTKView

@dynamic delegate;

- (void)setDelegate:(id<PTKViewDelegate> __nullable)delegate {
    self.internalDelegate = delegate;
}

- (id<PTKViewDelegate> __nullable)delegate {
    return self.internalDelegate;
}

- (void)onChange {
    [super onChange];
    [self.internalDelegate paymentView:self withCard:[self card] isValid:self.isValid];
}

- (PTKCard * __nonnull)card {
    PTKCard *card = [[PTKCard alloc] init];
    card.number = self.cardNumber;
    card.expMonth = self.expirationMonth;
    card.expYear = self.expirationYear;
    card.cvc = self.cvc;
    return card;
}

@end

#pragma clang diagnostic pop
