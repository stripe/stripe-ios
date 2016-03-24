//
//  STPPaymentEmailView.h
//  Stripe
//
//  Created by Jack Flintermann on 3/23/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPBlocks.h"

@class STPEmailEntryView;

@protocol STPEmailEntryViewDelegate <NSObject>

- (void)emailEntryView:(STPEmailEntryView *)emailView
  didEnterEmailAddress:(NSString *)emailAddress
            completion:(STPErrorBlock)completion;

@end

@interface STPEmailEntryView : UIView
@property(nonatomic, weak) id<STPEmailEntryViewDelegate> delegate;
@end
