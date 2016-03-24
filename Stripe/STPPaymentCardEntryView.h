//
//  STPPaymentCardEntryView.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"
#import "STPCardParams.h"

@class STPPaymentCardEntryView;

@protocol STPPaymentCardEntryViewDelegate

- (void)paymentCardEntryView:(STPPaymentCardEntryView *)emailView
          didEnterCardParams:(STPCardParams *)params
                  completion:(STPErrorBlock)completion;

@end

@interface STPPaymentCardEntryView : UIView

@property(nonatomic, weak) id<STPPaymentCardEntryViewDelegate> delegate;

@end
