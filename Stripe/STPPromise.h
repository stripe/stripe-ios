//
//  STPPromise.h
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STPBlocks.h"

NS_ASSUME_NONNULL_BEGIN

@class STPVoidPromise;

@interface STPPromise<T>: NSObject

typedef void (^STPPromiseErrorBlock)(NSError *error);
typedef void (^STPPromiseValueBlock)(T value);
typedef STPPromise* _Nonnull (^STPPromiseFlatMapBlock)(T value);

@property(atomic, readonly)BOOL completed;
@property(atomic, readonly)T value;
@property(atomic, readonly)NSError *error;

- (void)succeed:(T)value;
- (void)fail:(NSError *)error;

- (instancetype)onSuccess:(STPPromiseValueBlock)callback;
- (instancetype)onFailure:(STPPromiseErrorBlock)callback;

- (STPPromise<id> *)flatMap:(STPPromiseFlatMapBlock)callback;
- (STPVoidPromise *)asVoid;

@end

typedef STPPromise* _Nonnull (^STPVoidPromiseFlatMapBlock)();

@interface STPVoidPromise : STPPromise

- (void)succeed;
- (instancetype)voidOnSuccess:(STPVoidBlock)block;
- (STPPromise<id> *)voidFlatMap:(STPVoidPromiseFlatMapBlock)block;

@end

NS_ASSUME_NONNULL_END
