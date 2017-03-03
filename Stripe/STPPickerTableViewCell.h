//
//  STPPickerTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPTextFieldTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@protocol STPPickerDataSource;

@interface STPPickerTableViewCell : STPTextFieldTableViewCell

@property(nonatomic) id<STPPickerDataSource> pickerDataSource;

@end

@protocol STPPickerDataSource <NSObject>

- (NSInteger)numberOfRows;
- (NSInteger)indexOfValue:(NSString *)value;
- (NSString *)valueForRow:(NSInteger)row;
- (NSString *)titleForRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
