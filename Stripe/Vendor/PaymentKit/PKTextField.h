//
//  PKTextField.h
//  PaymentKit Example
//
//  Created by Michaël Villar on 3/20/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PKTextField;

@interface PKTextField : UITextField

+ (NSString*)textByRemovingUselessSpacesFromString:(NSString*)string;

@end
