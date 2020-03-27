//
//  STPLabeledMultiFormTextFieldView.h
//  StripeiOS
//
//  Created by Cameron Sabol on 3/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STPFormTextField;

NS_ASSUME_NONNULL_BEGIN

@interface STPLabeledMultiFormTextFieldView : UIView

- (instancetype)initWithFormLabel:(NSString *)formLabelText
                   firstTextField:(STPFormTextField *)textField1
                  secondTextField:(STPFormTextField *)textField2;

@property (nonatomic) UIColor *formBackgroundColor;

@end

NS_ASSUME_NONNULL_END
