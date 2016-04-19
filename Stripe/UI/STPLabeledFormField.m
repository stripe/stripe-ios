//
//  STPLabeledFormField.m
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import "STPLabeledFormField.h"
#import "STPFormTextField.h"
#import "UIImage+Stripe.h"

@interface STPLabeledFormField()

@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic, nullable, weak) STPFormTextField *formTextField;

@end

@implementation STPLabeledFormField

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *imageView = [UIImageView new];
        _imageView = imageView;
        _imageView.contentMode = UIViewContentModeCenter;
        [self addSubview:imageView];
        UILabel *captionLabel = [UILabel new];
        _captionLabel = captionLabel;
        [self addSubview:captionLabel];
        STPFormTextField *formTextField = [STPFormTextField new];
        formTextField.placeholderColor = [UIColor lightGrayColor];
        _formTextField = formTextField;
        [self addSubview:formTextField];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat subViewHeight = self.bounds.size.height - self.edgeInsets.top - self.edgeInsets.bottom;
    self.imageView.frame = CGRectMake(self.edgeInsets.left,
                                      self.edgeInsets.top,
                                      self.imageView.image.size.width,
                                      subViewHeight);
    [self.captionLabel sizeToFit];
    self.captionLabel.frame = CGRectMake(CGRectGetMaxX(self.imageView.frame) + self.padding,
                                         self.edgeInsets.top,
                                         CGRectGetWidth(self.captionLabel.frame),
                                         subViewHeight);
    CGFloat formX = CGRectGetMaxX(self.captionLabel.frame) + self.padding;
    self.formTextField.frame = CGRectMake(formX,
                                          self.edgeInsets.top,
                                          CGRectGetWidth(self.frame) - formX - self.edgeInsets.right,
                                          subViewHeight);
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = [image copy];
}

- (UIImage *)image {
    return [self.imageView.image copy];
}

- (void)setEdgeInsets:(UIEdgeInsets)edgeInsets {
    _edgeInsets = edgeInsets;
    [self setNeedsLayout];
}

- (void)setPadding:(CGFloat)padding {
    _padding = padding;
    [self setNeedsLayout];
}

@end
