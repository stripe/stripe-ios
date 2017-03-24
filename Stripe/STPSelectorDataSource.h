//
//  STPSelectorDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STPSelectorDataSource <NSObject>

@property (nonatomic, readonly) NSInteger selectedRow;

- (NSString *)selectorTitle;
- (NSInteger)numberOfRowsInSelector;
- (nullable NSString *)selectorValueForRow:(NSInteger)row;
- (NSString *)selectorTitleForRow:(NSInteger)row;
- (nullable UIImage *)selectorImageForRow:(NSInteger)row;
- (BOOL)selectRowWithValue:(nullable NSString *)value;

@end

NS_ASSUME_NONNULL_END
