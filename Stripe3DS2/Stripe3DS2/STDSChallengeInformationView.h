//
//  STDSChallengeInformationView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/4/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSLabelCustomization.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeInformationView: UIView

@property (nonatomic, strong, nullable) NSString *headerText;
@property (nonatomic, strong, nullable) UIImage *textIndicatorImage;
@property (nonatomic, strong, nullable) NSString *challengeInformationText;
@property (nonatomic, strong, nullable) NSString *challengeInformationLabel;

@property (nonatomic, strong, nullable) STDSLabelCustomization *labelCustomization;

@end

NS_ASSUME_NONNULL_END
