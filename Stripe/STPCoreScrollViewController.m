//
//  STPCoreScrollViewController.m
//  Stripe
//
//  Created by Brian Dorfman on 1/6/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreScrollViewController.h"
#import "STPCoreScrollViewController+Private.h"

#import "STPColorUtils.h"
#import "STPTheme.h"

// Note:
// The private class extension for this class is in
// STPCoreScrollViewController+Private.h

@implementation STPCoreScrollViewController

- (UIScrollView *)createScrollView {
    return [UIScrollView new];
}

- (void)createAndSetupViews {
    [super createAndSetupViews];
    _scrollView = [self createScrollView];
    [self.view addSubview:self.scrollView];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;
}

- (void)updateAppearance {
    [super updateAppearance];

    self.scrollView.backgroundColor = self.theme.primaryBackgroundColor;
    self.scrollView.tintColor = self.theme.accentColor;

    if ([STPColorUtils colorIsBright:self.theme.primaryBackgroundColor]) {
        self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    } else {
        self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (self.navigationController.navigationBar.translucent) {
        CGFloat insetTop = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        self.scrollView.contentInset = UIEdgeInsetsMake(insetTop, 0, 0, 0);
        self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset;
    } else {
        self.scrollView.contentInset = UIEdgeInsetsZero;
        self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    CGPoint offset = self.scrollView.contentOffset;
    offset.y = -self.scrollView.contentInset.top;
    self.scrollView.contentOffset = offset;
    
}

@end
