//
//  STPPromise.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STPPromise<T>: NSObject

typedef void (^STPPromiseErrorBlock)(NSError *error);
typedef void (^STPPromiseValueBlock)(T value);

@property(atomic, readonly)BOOL completed;
@property(atomic, readonly)T value;
@property(atomic, readonly)NSError *error;

- (void)succeed:(T)value;
- (void)fail:(NSError *)error;

- (instancetype)onSuccess:(void (^)(T value))callback;
- (instancetype)onFailure:(void (^)(NSError *error))callback;

@end

NS_ASSUME_NONNULL_END
