//
//  STPCardScannerTableViewCell.m
//  Stripe
//
//  Created by David Estes on 8/17/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

#import "STPCardScannerTableViewCell.h"
#import "STPCameraView.h"

#import "STPTheme.h"
#import "UIView+Stripe_SafeAreaBounds.h"

@interface STPCardScannerTableViewCell()

@property (nonatomic, weak) STPCameraView *cameraView;

@end

@implementation STPCardScannerTableViewCell

static const CGFloat cardSizeRatio = 2.125f/3.370f; // ID-1 card size (in inches)

- (instancetype)init {
    self = [super init];
    if (self) {
        STPCameraView *cameraView = [[STPCameraView alloc] initWithFrame:self.bounds];
        [self.contentView addSubview:cameraView];
        _cameraView = cameraView;
        _theme = [STPTheme defaultTheme];
        [self.cameraView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.contentView addConstraints:@[
                               [cameraView.heightAnchor constraintEqualToAnchor:cameraView.widthAnchor multiplier:cardSizeRatio],
                               [cameraView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:0],
                               [cameraView.leftAnchor constraintEqualToAnchor:self.contentView.leftAnchor constant:0],
                               [cameraView.rightAnchor constraintEqualToAnchor:self.contentView.rightAnchor constant:0],
                               [cameraView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:0]]];
        [self updateAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
}

- (void)setTheme:(STPTheme *)theme {
    _theme = theme;
    [self updateAppearance];
}

- (void)updateAppearance {
    // The first few frames of the camera view will be black, so our background should be black too.
    self.cameraView.backgroundColor = [UIColor blackColor];
}

@end
