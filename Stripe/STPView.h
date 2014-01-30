//
//  STPView.h
//
//  Created by Alex MacCaw on 2/14/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stripe.h"
#import "PKView.h"

#define STPCardErrorUserMessage NSLocalizedString(@"Your card is invalid", @"Error when the card is not valid")

typedef void (^STPTokenBlock)(STPToken* token, NSError* error);

@class STPView;

@protocol STPViewDelegate <NSObject>
@optional
- (void) stripeView:(STPView *)view withCard:(PKCard *)card isValid:(BOOL)valid;
- (BOOL) stripeView:(STPView *)view willShowMetaWithCard:(PKCard *)card;
- (void) stripeView:(STPView *)view withCard:(PKCard *)card cardNumberIsValid:(BOOL)valid;
@end

@interface STPView : UIView <PKViewDelegate>

- (id)initWithFrame: (CGRect)frame andKey: (NSString*)stripeKey;

@property IBOutlet PKView* paymentView;
@property (copy) NSString* key;
@property id <STPViewDelegate> delegate;
@property (readonly) BOOL pending;

- (void)createToken:(STPTokenBlock)block;

@end
