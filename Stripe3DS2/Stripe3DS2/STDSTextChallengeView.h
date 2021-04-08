//
//  STDSTextChallengeView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/5/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSTextFieldCustomization.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSTextField: UITextField

@end

@interface STDSTextChallengeView : UIView

@property (nonatomic, strong, nullable) STDSTextFieldCustomization *textFieldCustomization;
@property (nonatomic, copy, readonly, nullable) NSString *inputText;
@property (nonatomic, strong) STDSTextField *textField;

@end

NS_ASSUME_NONNULL_END
