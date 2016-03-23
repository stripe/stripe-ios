//
//  STPPaymentEmailView.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPPaymentEmailView;

@protocol STPPaymentEmailViewDelegate <NSObject>

- (void)paymentEmailView:(STPPaymentEmailView *)emailView didEnterEmailAddress:(NSString *)emailAddress completion:(STPErrorBlock)completion;

@end

@interface STPPaymentEmailView : UIView
@property(nonatomic, weak) id<STPPaymentEmailViewDelegate> delegate;
@end
