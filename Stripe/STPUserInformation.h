//
//  STPUserInformation.h
//  Stripe
//
//  Created by Jack Flintermann on 6/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// TODO document me

@interface STPUserInformation : NSObject

@property(nonatomic, copy, nullable)NSString *email;
@property(nonatomic, copy, nullable)NSString *phone;

@end

NS_ASSUME_NONNULL_END
