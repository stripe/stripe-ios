//
//  STPPromise.m
//  Stripe
//
//  Created by Jack Flintermann on 4/20/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPromise.h"

@interface STPPromise<T>()

@property(atomic)T value;
@property(atomic)NSError *error;
@property(atomic)NSArray<STPPromiseValueBlock> *successCallbacks;
@property(atomic)NSArray<STPPromiseErrorBlock> *errorCallbacks;

@end

@implementation STPPromise

- (instancetype)init {
    self = [super init];
    if (self) {
        _successCallbacks = [NSArray array];
        _errorCallbacks = [NSArray array];
    }
    return self;
}

- (BOOL)completed {
    return (self.error != nil || self.value != nil);
}

- (void)succeed:(id)value {
    if (self.completed) {
        return;
    }
    self.value = value;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (STPPromiseValueBlock valueBlock in self.successCallbacks) {
            valueBlock(value);
        }
    });
}

- (void)fail:(NSError *)error {
    if (self.completed) {
        return;
    }
    self.error = error;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (STPPromiseErrorBlock errorBlock in self.errorCallbacks) {
            errorBlock(error);
        }
    });
}

- (instancetype)onSuccess:(STPPromiseValueBlock)callback {
    if (self.value) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(self.value);
        });
    } else {
        self.successCallbacks = [self.successCallbacks arrayByAddingObject:callback];
    }
    return self;
}

- (instancetype)onFailure:(STPPromiseErrorBlock)callback {
    if (self.error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(self.error);
        });
    } else {
        self.errorCallbacks = [self.errorCallbacks arrayByAddingObject:callback];
    }
    return self;
}

@end
