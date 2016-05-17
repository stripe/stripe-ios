//
//  STPObscuredCardView.m
//  Stripe
//
//  Created by Jack Flintermann on 5/11/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPObscuredCardView.h"
#import "UIImage+Stripe.h"

@interface STPObscuredCardView()<UITextFieldDelegate>

@property(nonatomic, weak) UIImageView *brandImageView;
@property(nonatomic, weak) UITextField *last4Field;
@property(nonatomic, weak) UITextField *expField;

@end

@implementation STPObscuredCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImage *cardImage = [UIImage stp_unknownCardCardImage];
        UIImageView *brandImageView = [[UIImageView alloc] initWithImage:cardImage];
        brandImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:brandImageView];
        _brandImageView = brandImageView;
        
        UITextField *last4Field = [UITextField new];
        last4Field.delegate = self;
        [self addSubview:last4Field];
        _last4Field = last4Field;
        
        UITextField *expField = [UITextField new];
        expField.delegate = self;
        [self addSubview:expField];
        _expField = expField;
        
        _theme = [STPTheme new];
        [self updateAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.brandImageView.frame = CGRectMake(10, 2, self.brandImageView.image.size.width, self.bounds.size.height - 2);
    
    [self.last4Field sizeToFit];
    self.last4Field.frame = CGRectMake(CGRectGetMaxX(self.brandImageView.frame) + 8, 0, self.last4Field.frame.size.width + 20, self.bounds.size.height);
    
    [self.expField sizeToFit];
    CGRect expFrame = self.expField.frame;
    expFrame.size.width += 20;
    self.expField.frame = expFrame;
    self.expField.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.backgroundColor = self.theme.secondaryBackgroundColor;
    self.last4Field.backgroundColor = [UIColor clearColor];
    self.last4Field.font = self.theme.font;
    self.last4Field.textColor = self.theme.primaryForegroundColor;
    
    self.expField.backgroundColor = [UIColor clearColor];
    self.expField.font = self.theme.font;
    self.expField.textColor = self.theme.primaryForegroundColor;
}

- (void)configureWithCard:(STPCard *)card {
    UIImage *image = [UIImage stp_brandImageForCardBrand:card.brand];
    self.brandImageView.image = image;
    self.last4Field.text = card.last4;
    self.expField.text = [NSString stringWithFormat:@"%lu/%lu", card.expMonth, card.expYear % 100];
    [self setNeedsLayout];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL deleting = (range.location == textField.text.length - 1 && range.length == 1 && [string isEqualToString:@""]);
    if (deleting) {
        self.last4Field.text = @"";
        self.expField.text = @"";
        [self.delegate obscuredCardViewDidClear:self];
    }
    return NO;
}

@end
