//
//  STPPublishableKeyStore.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPPublishableKeyStore : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString *publishableKey;

@end
