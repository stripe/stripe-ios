//
//  STPBackendAPIAdapter.h
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "STPAddress.h"

@class STPCard, STPToken;

typedef void (^STPCardCompletionBlock)(STPCard * __nullable selectedCard, NSArray<STPCard *>* __nullable cards, NSError * __nullable error);
typedef void (^STPAddressCompletionBlock)(STPAddress * __nullable address, NSError * __nullable error);

@protocol STPBackendAPIAdapter<NSObject>

- (void)retrieveCards:(nonnull STPCardCompletionBlock)completion;
- (void)addToken:(nonnull STPToken *)token completion:(nonnull STPCardCompletionBlock)completion;
- (void)selectCard:(nonnull STPCard *)card completion:(nonnull STPCardCompletionBlock)completion;

@end
