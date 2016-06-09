//
//  STPCustomer.h
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPCustomer : NSObject

@property(nonatomic, readonly, copy)NSString *stripeID;
@property(nonatomic, readonly) id<STPSource> defaultSource;
@property(nonatomic, readonly, nullable) NSArray<id<STPSource>> *sources;

@end

@interface STPCustomerDeserializer : NSObject

- (instancetype)initWithData:(nullable NSData *)data
                 urlResponse:(nullable NSURLResponse *)urlResponse
                       error:(nullable NSError *)error;

@property(nonatomic, readonly, nullable)STPCustomer *customer;
@property(nonatomic, readonly, nullable)NSError *error;

@end

NS_ASSUME_NONNULL_END
