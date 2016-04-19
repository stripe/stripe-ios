//
//  STPAbstractAPIAdapter.h
//  Stripe
//
//  Created by Ben Guo on 4/19/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol STPSource;

typedef void (^STPSourceCompletionBlock)(id<STPSource> __nullable selectedSource, NSArray<id<STPSource>>* __nullable sources, NSError * __nullable error);

@interface STPAbstractAPIAdapter : NSObject

@property(nonatomic, nullable, readwrite)NSArray<id<STPSource>>* sources;
@property(nonatomic, nullable, readwrite)id<STPSource> selectedSource;

@end
