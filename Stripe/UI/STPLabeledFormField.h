//
//  STPLabeledFormField.h
//  Stripe
//
//  Created by Jack Flintermann on 10/15/15.
//  Copyright © 2015 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPFormTextField;

@interface STPLabeledFormField : UIView

@property (nonatomic) CGFloat padding;
@property (nonatomic) UIEdgeInsets edgeInsets;
@property (nonatomic, nullable, copy) UIImage *image;
@property (nonatomic, nullable, weak) UILabel *captionLabel;
@property (nonatomic, weak, nullable, readonly) STPFormTextField *formTextField;

@end
