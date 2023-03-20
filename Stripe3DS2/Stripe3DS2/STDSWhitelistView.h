//
//  STDSWhitelistView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSChallengeResponseSelectionInfo.h"
#import "STDSLabelCustomization.h"
#import "STDSSelectionCustomization.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSWhitelistView : UIView

@property (nonatomic, strong, nullable) NSString *whitelistText;
@property (nonatomic, readonly, nullable) id<STDSChallengeResponseSelectionInfo> selectedResponse;
@property (nonatomic, strong, nullable) STDSLabelCustomization *labelCustomization;
@property (nonatomic, strong, nullable) STDSSelectionCustomization *selectionCustomization;

@end

NS_ASSUME_NONNULL_END
