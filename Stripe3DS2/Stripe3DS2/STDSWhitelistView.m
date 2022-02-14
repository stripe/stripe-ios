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
#import "STDSChallengeResponseSelectionInfoObject.h"
#import "NSString+EmptyChecking.h"
#import "UIView+LayoutSupport.h"
#import "STDSSelectionButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSWhitelistView()

@property (nonatomic, strong) UILabel *whitelistLabel;
@property (nonatomic, strong) STDSSelectionButton *selectionButton;

@end

@implementation STDSWhitelistView

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
    
    self.selectionButton = [[STDSSelectionButton alloc] initWithCustomization:self.selectionCustomization];
    self.selectionButton.isCheckbox = YES;
    [self.selectionButton addTarget:self action:@selector(_selectionButtonWasTapped) forControlEvents:UIControlEventTouchUpInside];
    
    UIStackView *stackView = [self _buildStackView];
    [stackView addArrangedSubview:self.selectionButton];
    [stackView addArrangedSubview:self.whitelistLabel];

    [containerView addArrangedSubview:stackView];
}

- (void)setWhitelistText:(NSString * _Nullable)whitelistText {
    _whitelistText = whitelistText;
    
    self.whitelistLabel.text = whitelistText;
    self.whitelistLabel.hidden = [NSString _stds_isStringEmpty:whitelistText];
    self.selectionButton.hidden = self.whitelistLabel.hidden;
}

- (id<STDSChallengeResponseSelectionInfo> _Nullable)selectedResponse {
    if (self.selectionButton.selected) {
        return [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"Y" value:STDSLocalizedString(@"Yes", @"The yes answer to a yes or no question.")];;
    }
    
    return [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:@"N" value:STDSLocalizedString(@"No", @"The no answer to a yes or no question.")];
}

- (void)setLabelCustomization:(STDSLabelCustomization * _Nullable)labelCustomization {
    _labelCustomization = labelCustomization;
    
    self.whitelistLabel.font = labelCustomization.font;
    self.whitelistLabel.textColor = labelCustomization.textColor;
}

- (void)setSelectionCustomization:(STDSSelectionCustomization * _Nullable)selectionCustomization {
    _selectionCustomization = selectionCustomization;
    self.selectionButton.customization = selectionCustomization;
}

- (UIStackView *)_buildStackView {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFillProportionally;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.spacing = 20;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    return stackView;
}

- (void)_selectionButtonWasTapped {
    self.selectionButton.selected = !self.selectionButton.selected;
}

@end

NS_ASSUME_NONNULL_END
