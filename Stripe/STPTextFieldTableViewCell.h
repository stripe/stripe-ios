//
//  STPTextFieldTableViewCell.h
//  Stripe
//
//  Created by Ben Guo on 2/9/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STPFormTextField.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^STPTextValidationBlock)(NSString *contents, BOOL editing);

@class STPTextFieldTableViewCell, STPTheme, STPFormTextField;

@protocol STPTextFieldTableViewCellDelegate <NSObject>

- (void)textFieldTableViewCellDidUpdateText:(STPTextFieldTableViewCell *)cell;

@optional
- (void)textFieldTableViewCellDidBackspaceOnEmpty:(STPTextFieldTableViewCell *)cell;
- (void)textFieldTableViewCellDidReturn:(STPTextFieldTableViewCell *)cell;

@end

@interface STPTextFieldTableViewCell : UITableViewCell <STPFormTextFieldDelegate>

@property (nonatomic, copy) STPTextValidationBlock textValidationBlock;
@property(nonatomic)STPTheme *theme;
@property(nonatomic, copy) NSString *placeholder;
@property(nonatomic, copy) NSString *contents;
@property(nonatomic, weak)id<STPTextFieldTableViewCellDelegate>delegate;
@property(nonatomic, weak) STPFormTextField *textField;
@property(nonatomic, assign) BOOL lastInList;
@property(nonatomic, readonly) BOOL isValid;

@end

NS_ASSUME_NONNULL_END
