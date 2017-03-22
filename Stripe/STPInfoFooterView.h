//
//  STPInfoFooterView.h
//  Stripe
//
//  Created by Ben Guo on 3/15/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPTheme.h"

NS_ASSUME_NONNULL_BEGIN
@interface STPInfoFooterView : UIView<UITextViewDelegate>

@property(nonatomic, weak, readonly)UITextView *textView;
@property(nonatomic)STPTheme *theme;
@property(nonatomic)UIEdgeInsets insets;

- (CGFloat)heightForWidth:(CGFloat)maxWidth;
- (void)updateAppearance;

@end
NS_ASSUME_NONNULL_END
