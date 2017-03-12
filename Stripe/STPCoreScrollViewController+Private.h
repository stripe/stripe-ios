//
//  STPCoreScrollViewController+Private.h
//  Stripe
//
//  Created by Brian Dorfman on 1/10/17.
//  Copyright © 2017 Stripe, Inc. All rights reserved.
//

#import "STPCoreScrollViewController.h"
#import "STPCoreViewController+Private.h"

NS_ASSUME_NONNULL_BEGIN

/**
 This class extension contains properties and methods that are intended to
 be for private Stripe usage only, and are here to be hidden from the public
 api in STPCoreScrollViewController.h

 All Stripe view controllers which inherit from STPCoreScrollViewController 
 should also import this file.
 */
@interface STPCoreScrollViewController ()

/**
 This returns the scroll view being managed by the view controller
 */
@property (nonatomic, nullable, readonly) UIScrollView *scrollView;

/**
 This method is used by the base implementation to create the object
 backing the `scrollView` property. Subclasses can override to change the
 type of the scroll view (eg UITableView or UICollectionView instead of
 UIScrollView).
 */
- (UIScrollView *)createScrollView;

@end

NS_ASSUME_NONNULL_END
