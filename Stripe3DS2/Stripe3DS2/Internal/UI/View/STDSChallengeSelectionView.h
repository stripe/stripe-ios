//
//  STDSChallengeSelectionView.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/6/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STDSChallengeResponseSelectionInfo.h"
#import "STDSLabelCustomization.h"
#import "STDSSelectionCustomization.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STDSChallengeSelectionStyle) {
    
    /// A display style for selecting a single option.
    STDSChallengeSelectionStyleSingle = 0,
    
    /// A display style for selection multiple options.
    STDSChallengeSelectionStyleMulti = 1,
};

@interface STDSChallengeSelectionView : UIView

@property (nonatomic, strong, readonly) NSArray<id<STDSChallengeResponseSelectionInfo>> *currentlySelectedChallengeInfo;
@property (nonatomic, strong) STDSLabelCustomization *labelCustomization;
@property (nonatomic, strong) STDSSelectionCustomization *selectionCustomization;

- (instancetype)initWithChallengeSelectInfo:(NSArray<id<STDSChallengeResponseSelectionInfo>> *)challengeSelectInfo selectionStyle:(STDSChallengeSelectionStyle)selectionStyle;

@end

NS_ASSUME_NONNULL_END
