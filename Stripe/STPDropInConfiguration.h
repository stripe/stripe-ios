//
//  STPDropInConfiguration.h
//  Stripe
//
//  Created by Ben Guo on 5/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPAPIResponseDecodable.h"

NS_ASSUME_NONNULL_BEGIN

@class STPDropInConfiguration;

typedef void (^STPDropInConfigurationCompletionBlock)(STPDropInConfiguration * __nullable configuration, NSError * __nullable error);

@protocol STPDropInConfigurationProvider <NSObject>

- (void)retrieveConfiguration:(STPDropInConfigurationCompletionBlock)completion;

@end

@interface STPDropInConfiguration : NSObject <STPAPIResponseDecodable>

@property (nonatomic, readonly) NSString *publishableKey;
@property (nonatomic, readonly) NSString *customerID;
@property (nonatomic, readonly) NSString *customerResourceKey;
@property (nonatomic, readonly) NSDate *customerResourceKeyExpirationDate;

@end

NS_ASSUME_NONNULL_END
