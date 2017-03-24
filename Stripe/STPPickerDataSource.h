//
//  STPPickerDataSource.h
//  Stripe
//
//  Created by Ben Guo on 3/20/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol STPPickerDataSource <NSObject>

- (NSInteger)numberOfRowsInPicker;
- (NSInteger)indexOfPickerValue:(nullable NSString *)value;
- (nullable NSString *)pickerValueForRow:(NSInteger)row;
- (NSString *)pickerTitleForRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
