//
//  STDSWhitelistView.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 3/11/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSLocalizedString.h"
#import "STDSWhitelistView.h"
#import "STDSStackView.h"
#import "STDSChallengeSelectionView.h"
#import "STDSChallengeResponseSelectionInfoObject.h"
#import "NSString+EmptyChecking.h"
#import "UIView+LayoutSupport.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSWhitelistView()

@property (nonatomic, strong) UILabel *whitelistLabel;
@property (nonatomic, strong) STDSChallengeSelectionView *challengeSelectionView;

@end

@implementation STDSWhitelistView

static const CGFloat kWhitelistLabelSpacing = 5;
static const CGFloat kWhitelistChallengeSelectionTopPadding = 5;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self _setupViewHierarchy];
    }
    
    return self;
}

- (void)_setupViewHierarchy {
    self.layoutMargins = UIEdgeInsetsZero;
    
    STDSStackView *containerView = [[STDSStackView alloc] initWithAlignment:STDSStackViewLayoutAxisVertical];
    [self addSubview:containerView];
    [containerView _stds_pinToSuperviewBounds];
    
    self.whitelistLabel = [[UILabel alloc] init];
    self.whitelistLabel.numberOfLines = 0;
    [containerView addArrangedSubview:self.whitelistLabel];
    
    STDSChallengeResponseSelectionInfoObject *yesSelection = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Y" value:STDSLocalizedString(@"Yes", @"The yes answer to a yes or no question.")];
    STDSChallengeResponseSelectionInfoObject *noSelection = [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"N" value:STDSLocalizedString(@"No", @"The no answer to a yes or no question.")];

    self.challengeSelectionView = [[STDSChallengeSelectionView alloc] initWithChallengeSelectInfo:@[yesSelection, noSelection] selectionStyle:STDSChallengeSelectionStyleSingle];
    self.challengeSelectionView.layoutMargins = UIEdgeInsetsMake(kWhitelistChallengeSelectionTopPadding, 0, 0, 0);
    
    [containerView addSpacer:kWhitelistLabelSpacing];
    [containerView addArrangedSubview:self.challengeSelectionView];
}

- (void)setWhitelistText:(NSString * _Nullable)whitelistText {
    _whitelistText = whitelistText;
    
    self.whitelistLabel.text = whitelistText;
    self.whitelistLabel.hidden = [NSString _stds_isStringEmpty:whitelistText];
    self.challengeSelectionView.hidden = self.whitelistLabel.hidden;
}

- (id<STDSChallengeResponseSelectionInfo> _Nullable)selectedResponse {
    return self.challengeSelectionView.currentlySelectedChallengeInfo.firstObject;
}

- (void)setLabelCustomization:(STDSLabelCustomization * _Nullable)labelCustomization {
    _labelCustomization = labelCustomization;
    
    self.whitelistLabel.font = labelCustomization.font;
    self.whitelistLabel.textColor = labelCustomization.textColor;
    self.challengeSelectionView.labelCustomization = labelCustomization;
}

- (void)setSelectionCustomization:(STDSSelectionCustomization * _Nullable)selectionCustomization {
    _selectionCustomization = selectionCustomization;
    self.challengeSelectionView.selectionCustomization = selectionCustomization;
}

@end

NS_ASSUME_NONNULL_END
