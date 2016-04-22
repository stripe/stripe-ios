//
//  UIViewController+Stripe_KeyboardAvoiding.m
//  Stripe
//
//  Created by Jack Flintermann on 4/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIView+Stripe_FirstResponder.h"

// This is a private class that is only a UIViewController subclass by virtue of the fact
// that that makes it easier to attach to another UIViewController as a child.
@interface STPKeyboardDetectingViewController : UIViewController
@property(weak, nonatomic) UIScrollView *scrollView;
@property(nonatomic) CGPoint originalContentOffset;
@property(nonatomic) UIEdgeInsets originalContentInset;
@property(nonatomic) CGFloat currentScroll;
@property(nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@end

@implementation STPKeyboardDetectingViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingNone;
    self.view = view;
}

- (void)setScrollView:(UIScrollView *)scrollView {
    [_scrollView removeGestureRecognizer:self.tapGestureRecognizer];
    _scrollView = scrollView;
    [_scrollView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)endEditing {
    [self.scrollView endEditing:YES];
    [self.scrollView setContentOffset:self.originalContentOffset animated:YES];
}

- (void)tapped {
    [self endEditing];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    // The following is effectively detecting if the keyboard is about to appear.
    // If that's the case, we'll assume the scrollView has its contentOffset set
    // to the correct value by this point in time (i.e. if it's inside a UINavController).
    CGRect oldFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    if (!CGRectIntersectsRect(self.view.window.frame, oldFrame)) {
        self.originalContentOffset = self.scrollView.contentOffset;
        self.originalContentInset = self.scrollView.contentInset;
    }
    
    // As of iOS 8, this all takes place inside the necessary animation block
    // https://twitter.com/SmileyKeith/status/684100833823174656
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetMaxY(self.scrollView.frame) - CGRectGetMinY(keyboardFrame);
    [self updateInsetIfNecessary:keyboardHeight];
}

- (void)updateInsetIfNecessary:(CGFloat)keyboardHeight {
    UIEdgeInsets insets;
    UIEdgeInsets scrollInsets;
    if (fabs(keyboardHeight) < FLT_EPSILON) {
        insets = self.originalContentInset;
        scrollInsets = insets;
    } else {
        insets = UIEdgeInsetsMake(
                                  self.originalContentInset.top + 30,
                                  self.originalContentInset.left,
                                  self.originalContentInset.bottom + keyboardHeight + 20,
                                  self.originalContentInset.right
                                  );
        scrollInsets = UIEdgeInsetsMake(
                                        self.originalContentInset.top,
                                        self.originalContentInset.left,
                                        self.originalContentInset.bottom + keyboardHeight,
                                        self.originalContentInset.right
                                        );
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(self.scrollView.contentInset, insets)) {
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = scrollInsets;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.scrollView endEditing:YES];
    [coordinator animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.scrollView setContentOffset:self.originalContentOffset animated:YES];
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self endEditing];
}
#pragma clang diagnostic pop


@end

@implementation UIViewController (Stripe_KeyboardAvoiding)

- (void)stp_beginAvoidingKeyboardWithScrollView:(UIScrollView *)scrollView {
    STPKeyboardDetectingViewController *keyboardAvoiding = [STPKeyboardDetectingViewController new];
    keyboardAvoiding.scrollView = scrollView;
    [self addChildViewController:keyboardAvoiding];
    [self.view addSubview:keyboardAvoiding.view];
    [keyboardAvoiding didMoveToParentViewController:self];
}

@end
