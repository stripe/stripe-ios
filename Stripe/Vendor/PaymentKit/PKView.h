//
//  PKPaymentField.h
//  PKPayment Example
//
//  Created by Alex MacCaw on 1/22/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PKCard.h"
#import "PKCardNumber.h"
#import "PKCardExpiry.h"
#import "PKCardCVC.h"
#import "PKAddressZip.h"
#import "PKUSAddressZip.h"

@class PKView;

@protocol PKViewDelegate <NSObject>
@optional
- (void) paymentView:(PKView*)paymentView withCard:(PKCard*)card isValid:(BOOL)valid;
@end

@interface PKView : UIView <UITextFieldDelegate>

- (BOOL)isValid;

@property (nonatomic, readonly) PKCardNumber* cardNumber;
@property (nonatomic, readonly) PKCardExpiry* cardExpiry;
@property (nonatomic, readonly) PKCardCVC* cardCVC;
@property (nonatomic, readonly) PKAddressZip* addressZip;

@property IBOutlet UIView* innerView;
@property IBOutlet UIView* clipView;
@property IBOutlet UITextField* cardNumberField;
@property IBOutlet UITextField* cardExpiryField;
@property IBOutlet UITextField* cardCVCField;
@property IBOutlet UITextField* addressZipField;
@property IBOutlet UIImageView* placeholderView;
@property id <PKViewDelegate> delegate;
@property (readonly) PKCard* card;
@property (setter = setUSAddress:) BOOL usAddress;

@end
