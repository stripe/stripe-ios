//
//  STPTestDataStore.h
//  StripeExample
//
//  Created by Jack Flintermann on 10/1/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import <Foundation/Foundation.h>

@protocol STPTestDataStore <NSObject>

@property(nonatomic) id selectedItem;
@property(nonatomic, readonly) NSArray *allItems;
- (NSArray *)descriptionsForItem:(id)item;

@end

#endif