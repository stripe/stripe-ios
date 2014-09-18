//
//  PTKPaymentField.m
//  PTKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#define RGB(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
#define DarkGreyColor RGB(0,0,0)
#define RedColor RGB(253,0,17)
#define DefaultBoldFont [UIFont boldSystemFontOfSize:17]

#define kPTKViewPlaceholderViewAnimationDuration 0.25

#define kPTKViewCardExpiryFieldStartX 84 + 200
#define kPTKViewCardCVCFieldStartX 177 + 200

#define kPTKViewCardExpiryFieldEndX 84
#define kPTKViewCardCVCFieldEndX 177

static NSString *const kPTKLocalizedStringsTableName = @"PaymentKit";
static NSString *const kPTKOldLocalizedStringsTableName = @"STPaymentLocalizable";

#import "PTKView.h"
#import "PTKTextField.h"

@interface PTKView () <PTKTextFieldDelegate> {
@private
    BOOL _isInitialState;
    BOOL _isValidState;
}

@property (nonatomic, readonly, assign) UIResponder *firstResponderField;
@property (nonatomic, readonly, assign) PTKTextField *firstInvalidField;
@property (nonatomic, readonly, assign) PTKTextField *nextFirstResponder;

- (void)setup;
- (void)setupPlaceholderView;
- (void)setupCardNumberField;
- (void)setupCardExpiryField;
- (void)setupCardCVCField;

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField;

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;
- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString;

@property (nonatomic) UIView *opaqueOverGradientView;
@property (nonatomic) PTKCardNumber *cardNumber;
@property (nonatomic) PTKCardExpiry *cardExpiry;
@property (nonatomic) PTKCardCVC *cardCVC;
@property (nonatomic) PTKAddressZip *addressZip;
@end

#pragma mark -

@implementation PTKView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (void)setup
{
    _isInitialState = YES;
    _isValidState = NO;

    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 290, 46);
    self.backgroundColor = [UIColor clearColor];

    UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    backgroundImageView.image = [[UIImage imageNamed:@"textfield"]
            resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    [self addSubview:backgroundImageView];

    self.innerView = [[UIView alloc] initWithFrame:CGRectMake(40, 12, self.frame.size.width - 40, 20)];
    self.innerView.clipsToBounds = YES;

    [self setupPlaceholderView];
    [self setupCardNumberField];
    [self setupCardExpiryField];
    [self setupCardCVCField];

    [self.innerView addSubview:self.cardNumberField];

    UIImageView *gradientImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 12, 34)];
    gradientImageView.image = [UIImage imageNamed:@"gradient"];
    [self.innerView addSubview:gradientImageView];

    self.opaqueOverGradientView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, 34)];
    self.opaqueOverGradientView.backgroundColor = [UIColor colorWithRed:0.9686 green:0.9686
                                                                   blue:0.9686 alpha:1.0000];
    self.opaqueOverGradientView.alpha = 0.0;
    [self.innerView addSubview:self.opaqueOverGradientView];

    [self addSubview:self.innerView];
    [self addSubview:self.placeholderView];

    [self stateCardNumber];
}


- (void)setupPlaceholderView
{
    self.placeholderView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 13, 32, 20)];
    self.placeholderView.backgroundColor = [UIColor clearColor];
    self.placeholderView.image = [UIImage imageNamed:@"placeholder"];

    CALayer *clip = [CALayer layer];
    clip.frame = CGRectMake(32, 0, 4, 20);
    clip.backgroundColor = [UIColor clearColor].CGColor;
    [self.placeholderView.layer addSublayer:clip];
}

- (void)setupCardNumberField
{
    self.cardNumberField = [[PTKTextField alloc] initWithFrame:CGRectMake(12, 0, 170, 20)];
    self.cardNumberField.delegate = self;
    self.cardNumberField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_number" defaultValue:@"1234 5678 9012 3456"];
    self.cardNumberField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardNumberField.textColor = DarkGreyColor;
    self.cardNumberField.font = DefaultBoldFont;

    [self.cardNumberField.layer setMasksToBounds:YES];
}

- (void)setupCardExpiryField
{
    self.cardExpiryField = [[PTKTextField alloc] initWithFrame:CGRectMake(kPTKViewCardExpiryFieldStartX, 0, 60, 20)];
    self.cardExpiryField.delegate = self;
    self.cardExpiryField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_expiry" defaultValue:@"MM/YY"];
    self.cardExpiryField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardExpiryField.textColor = DarkGreyColor;
    self.cardExpiryField.font = DefaultBoldFont;

    [self.cardExpiryField.layer setMasksToBounds:YES];
}

- (void)setupCardCVCField
{
    self.cardCVCField = [[PTKTextField alloc] initWithFrame:CGRectMake(kPTKViewCardCVCFieldStartX, 0, 55, 20)];
    self.cardCVCField.delegate = self;
    self.cardCVCField.placeholder = [self.class localizedStringWithKey:@"placeholder.card_cvc" defaultValue:@"CVC"];
    self.cardCVCField.keyboardType = UIKeyboardTypeNumberPad;
    self.cardCVCField.textColor = DarkGreyColor;
    self.cardCVCField.font = DefaultBoldFont;

    [self.cardCVCField.layer setMasksToBounds:YES];
}

// Checks both the old and new localization table (we switched in 3/14 to PaymentKit.strings).
// Leave this in for a long while to preserve compatibility.
+ (NSString *)localizedStringWithKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    NSString *value = NSLocalizedStringFromTable(key, kPTKLocalizedStringsTableName, nil);
    if (value && ![value isEqualToString:key]) { // key == no value
        return value;
    } else {
        value = NSLocalizedStringFromTable(key, kPTKOldLocalizedStringsTableName, nil);
        if (value && ![value isEqualToString:key]) {
            return value;
        }
    }

    return defaultValue;
}

#pragma mark - Accessors

- (PTKCardNumber *)cardNumber
{
    return [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
}

- (PTKCardExpiry *)cardExpiry
{
    return [PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text];
}

- (PTKCardCVC *)cardCVC
{
    return [PTKCardCVC cardCVCWithString:self.cardCVCField.text];
}

#pragma mark - State

- (void)stateCardNumber
{
    if (!_isInitialState) {
        // Animate left
        _isInitialState = YES;

        [UIView animateWithDuration:0.05 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.opaqueOverGradientView.alpha = 0.0;
                         } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:0.400
                              delay:0
                            options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction)
                         animations:^{
                             self.cardExpiryField.frame = CGRectMake(kPTKViewCardExpiryFieldStartX,
                                     self.cardExpiryField.frame.origin.y,
                                     self.cardExpiryField.frame.size.width,
                                     self.cardExpiryField.frame.size.height);
                             self.cardCVCField.frame = CGRectMake(kPTKViewCardCVCFieldStartX,
                                     self.cardCVCField.frame.origin.y,
                                     self.cardCVCField.frame.size.width,
                                     self.cardCVCField.frame.size.height);
                             self.cardNumberField.frame = CGRectMake(12,
                                     self.cardNumberField.frame.origin.y,
                                     self.cardNumberField.frame.size.width,
                                     self.cardNumberField.frame.size.height);
                         }
                         completion:^(BOOL completed) {
                             [self.cardExpiryField removeFromSuperview];
                             [self.cardCVCField removeFromSuperview];
                         }];
    }

    [self.cardNumberField becomeFirstResponder];
}

- (void)stateMeta
{
    _isInitialState = NO;

    CGSize cardNumberSize;
    CGSize lastGroupSize;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    if ([self.cardNumber.formattedString respondsToSelector:@selector(sizeWithAttributes:)]) {
        NSDictionary *attributes = @{NSFontAttributeName: DefaultBoldFont};

        cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
    } else {
        cardNumberSize = [self.cardNumber.formattedString sizeWithFont:DefaultBoldFont];
        lastGroupSize = [self.cardNumber.lastGroup sizeWithFont:DefaultBoldFont];
    }
#else
    NSDictionary *attributes = @{NSFontAttributeName: DefaultBoldFont};

    cardNumberSize = [self.cardNumber.formattedString sizeWithAttributes:attributes];
    lastGroupSize = [self.cardNumber.lastGroup sizeWithAttributes:attributes];
#endif

    CGFloat frameX = self.cardNumberField.frame.origin.x - (cardNumberSize.width - lastGroupSize.width);

    [UIView animateWithDuration:0.05 delay:0.35 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.opaqueOverGradientView.alpha = 1.0;
                     } completion:^(BOOL finished) {
    }];
    [UIView animateWithDuration:0.400 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.cardExpiryField.frame = CGRectMake(kPTKViewCardExpiryFieldEndX,
                self.cardExpiryField.frame.origin.y,
                self.cardExpiryField.frame.size.width,
                self.cardExpiryField.frame.size.height);
        self.cardCVCField.frame = CGRectMake(kPTKViewCardCVCFieldEndX,
                self.cardCVCField.frame.origin.y,
                self.cardCVCField.frame.size.width,
                self.cardCVCField.frame.size.height);
        self.cardNumberField.frame = CGRectMake(frameX,
                self.cardNumberField.frame.origin.y,
                self.cardNumberField.frame.size.width,
                self.cardNumberField.frame.size.height);
    }                completion:nil];

    [self addSubview:self.placeholderView];
    [self.innerView addSubview:self.cardExpiryField];
    [self.innerView addSubview:self.cardCVCField];
    [self.cardExpiryField becomeFirstResponder];
}

- (void)stateCardCVC
{
    [self.cardCVCField becomeFirstResponder];
}

- (BOOL)isValid
{
    return [self.cardNumber isValid] && [self.cardExpiry isValid] &&
            [self.cardCVC isValidWithType:self.cardNumber.cardType];
}

- (PTKCard *)card
{
    PTKCard *card = [[PTKCard alloc] init];
    card.number = [self.cardNumber string];
    card.cvc = [self.cardCVC string];
    card.expMonth = [self.cardExpiry month];
    card.expYear = [self.cardExpiry year];

    return card;
}

- (void)setPlaceholderViewImage:(UIImage *)image
{
    if (![self.placeholderView.image isEqual:image]) {
        __block __unsafe_unretained UIView *previousPlaceholderView = self.placeholderView;
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 0.0;
                             self.placeholderView.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.2);
                         } completion:^(BOOL finished) {
            [previousPlaceholderView removeFromSuperview];
        }];
        self.placeholderView = nil;

        [self setupPlaceholderView];
        self.placeholderView.image = image;
        self.placeholderView.layer.opacity = 0.0;
        self.placeholderView.layer.transform = CATransform3DMakeScale(0.8, 0.8, 0.8);
        [self insertSubview:self.placeholderView belowSubview:previousPlaceholderView];
        [UIView animateWithDuration:kPTKViewPlaceholderViewAnimationDuration delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.placeholderView.layer.opacity = 1.0;
                             self.placeholderView.layer.transform = CATransform3DIdentity;
                         } completion:^(BOOL finished) {
        }];
    }
}

- (void)setPlaceholderToCVC
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];

    if (cardType == PTKCardTypeAmex) {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc-amex"]];
    } else {
        [self setPlaceholderViewImage:[UIImage imageNamed:@"cvc"]];
    }
}

- (void)setPlaceholderToCardType
{
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:self.cardNumberField.text];
    PTKCardType cardType = [cardNumber cardType];
    NSString *cardTypeName = @"placeholder";

    switch (cardType) {
        case PTKCardTypeAmex:
            cardTypeName = @"amex";
            break;
        case PTKCardTypeDinersClub:
            cardTypeName = @"diners";
            break;
        case PTKCardTypeDiscover:
            cardTypeName = @"discover";
            break;
        case PTKCardTypeJCB:
            cardTypeName = @"jcb";
            break;
        case PTKCardTypeMasterCard:
            cardTypeName = @"mastercard";
            break;
        case PTKCardTypeVisa:
            cardTypeName = @"visa";
            break;
        default:
            break;
    }

    [self setPlaceholderViewImage:[UIImage imageNamed:cardTypeName]];
}

#pragma mark - Delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField isEqual:self.cardCVCField]) {
        [self setPlaceholderToCVC];
    } else {
        [self setPlaceholderToCardType];
    }

    if ([textField isEqual:self.cardNumberField] && !_isInitialState) {
        [self stateCardNumber];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    if ([textField isEqual:self.cardNumberField]) {
        return [self cardNumberFieldShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardExpiryField]) {
        return [self cardExpiryShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    if ([textField isEqual:self.cardCVCField]) {
        return [self cardCVCShouldChangeCharactersInRange:range replacementString:replacementString];
    }

    return YES;
}

- (void)pkTextFieldDidBackSpaceWhileTextIsEmpty:(PTKTextField *)textField
{
    if (textField == self.cardCVCField)
        [self.cardExpiryField becomeFirstResponder];
    else if (textField == self.cardExpiryField)
        [self stateCardNumber];
}

- (BOOL)cardNumberFieldShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardNumberField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardNumber *cardNumber = [PTKCardNumber cardNumberWithString:resultString];

    if (![cardNumber isPartiallyValid])
        return NO;

    if (replacementString.length > 0) {
        self.cardNumberField.text = [cardNumber formattedStringWithTrail];
    } else {
        self.cardNumberField.text = [cardNumber formattedString];
    }

    [self setPlaceholderToCardType];

    if ([cardNumber isValid]) {
        [self textFieldIsValid:self.cardNumberField];
        [self stateMeta];

    } else if ([cardNumber isValidLength] && ![cardNumber isValidLuhn]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:YES];

    } else if (![cardNumber isValidLength]) {
        [self textFieldIsInvalid:self.cardNumberField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardExpiryShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardExpiryField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardExpiry *cardExpiry = [PTKCardExpiry cardExpiryWithString:resultString];

    if (![cardExpiry isPartiallyValid]) return NO;

    // Only support shorthand year
    if ([cardExpiry formattedString].length > 5) return NO;

    if (replacementString.length > 0) {
        self.cardExpiryField.text = [cardExpiry formattedStringWithTrail];
    } else {
        self.cardExpiryField.text = [cardExpiry formattedString];
    }

    if ([cardExpiry isValid]) {
        [self textFieldIsValid:self.cardExpiryField];
        [self stateCardCVC];

    } else if ([cardExpiry isValidLength] && ![cardExpiry isValidDate]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:YES];
    } else if (![cardExpiry isValidLength]) {
        [self textFieldIsInvalid:self.cardExpiryField withErrors:NO];
    }

    return NO;
}

- (BOOL)cardCVCShouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacementString
{
    NSString *resultString = [self.cardCVCField.text stringByReplacingCharactersInRange:range withString:replacementString];
    resultString = [PTKTextField textByRemovingUselessSpacesFromString:resultString];
    PTKCardCVC *cardCVC = [PTKCardCVC cardCVCWithString:resultString];
    PTKCardType cardType = [[PTKCardNumber cardNumberWithString:self.cardNumberField.text] cardType];

    // Restrict length
    if (![cardCVC isPartiallyValidWithType:cardType]) return NO;

    // Strip non-digits
    self.cardCVCField.text = [cardCVC string];

    if ([cardCVC isValidWithType:cardType]) {
        [self textFieldIsValid:self.cardCVCField];
    } else {
        [self textFieldIsInvalid:self.cardCVCField withErrors:NO];
    }

    return NO;
}


#pragma mark - Validations

- (void)checkValid
{
    if ([self isValid]) {
        _isValidState = YES;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:YES];
        }

    } else if (![self isValid] && _isValidState) {
        _isValidState = NO;

        if ([self.delegate respondsToSelector:@selector(paymentView:withCard:isValid:)]) {
            [self.delegate paymentView:self withCard:self.card isValid:NO];
        }
    }
}

- (void)textFieldIsValid:(UITextField *)textField
{
    textField.textColor = DarkGreyColor;
    [self checkValid];
}

- (void)textFieldIsInvalid:(UITextField *)textField withErrors:(BOOL)errors
{
    if (errors) {
        textField.textColor = RedColor;
    } else {
        textField.textColor = DarkGreyColor;
    }

    [self checkValid];
}

#pragma mark -
#pragma mark UIResponder
- (UIResponder *)firstResponderField;
{
    NSArray *responders = @[self.cardNumberField, self.cardExpiryField, self.cardCVCField];
    for (UIResponder *responder in responders) {
        if (responder.isFirstResponder) {
            return responder;
        }
    }

    return nil;
}

- (PTKTextField *)firstInvalidField;
{
    if (![[PTKCardNumber cardNumberWithString:self.cardNumberField.text] isValid])
        return self.cardNumberField;
    else if (![[PTKCardExpiry cardExpiryWithString:self.cardExpiryField.text] isValid])
        return self.cardExpiryField;
    else if (![[PTKCardCVC cardCVCWithString:self.cardCVCField.text] isValid])
        return self.cardCVCField;

    return nil;
}

- (PTKTextField *)nextFirstResponder;
{
    if (self.firstInvalidField)
        return self.firstInvalidField;

    return self.cardCVCField;
}

- (BOOL)isFirstResponder;
{
    return self.firstResponderField.isFirstResponder;
}

- (BOOL)canBecomeFirstResponder;
{
    return self.nextFirstResponder.canBecomeFirstResponder;
}

- (BOOL)becomeFirstResponder;
{
    return [self.nextFirstResponder becomeFirstResponder];
}

- (BOOL)canResignFirstResponder;
{
    return self.firstResponderField.canResignFirstResponder;
}

- (BOOL)resignFirstResponder;
{
    return [self.firstResponderField resignFirstResponder];
}

@end
