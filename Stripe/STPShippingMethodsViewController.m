//
//  STPShippingMethodsViewController.m
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPShippingMethodsViewController.h"
#import "STPLocalizationUtils.h"
#import "UIBarButtonItem+Stripe.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "STPImageLibrary+Private.h"
#import "STPColorUtils.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "STPShippingMethodTableViewCell.h"
#import "UINavigationBar+Stripe_Theme.h"

static NSString *const STPShippingMethodCellReuseIdentifier = @"STPShippingMethodCellReuseIdentifier";

@interface STPShippingMethodsViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic)NSArray<PKShippingMethod *>*shippingMethods;
@property(nonatomic)PKShippingMethod *selectedShippingMethod;
@property(nonatomic)STPTheme *theme;
@property(nonatomic)NSString *currency;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIImageView *imageView;
@property(nonatomic)UIBarButtonItem *doneItem;
@property(nonatomic)UIBarButtonItem *backItem;
@end

@implementation STPShippingMethodsViewController

- (instancetype)initWithShippingMethods:(NSArray<PKShippingMethod *>*)methods
                 selectedShippingMethod:(PKShippingMethod *)selectedMethod
                               currency:(NSString *)currency
                                  theme:(STPTheme *)theme {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _shippingMethods = methods;
        if (selectedMethod != nil && [methods indexOfObject:selectedMethod] != NSNotFound) {
            _selectedShippingMethod = selectedMethod;
        }
        else {
            _selectedShippingMethod = [methods stp_boundSafeObjectAtIndex:0];
        }
        _theme = theme;
        _currency = currency;
        self.title = STPLocalizedString(@"Shipping", @"Title for shipping info form");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [tableView registerClass:[STPShippingMethodTableViewCell class] forCellReuseIdentifier:STPShippingMethodCellReuseIdentifier];
    tableView.sectionHeaderHeight = 30;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)];
    self.doneItem = doneItem;
    self.backItem = [UIBarButtonItem stp_backButtonItemWithTitle:STPLocalizedString(@"Back", @"Text for back button") style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.stp_navigationItemProxy.rightBarButtonItem = doneItem;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeShippingImage]];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, imageView.bounds.size.height + (57 * 2));
    self.imageView = imageView;
    self.tableView.tableHeaderView = imageView;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self updateAppearance];
}

- (void)updateAppearance {
    self.view.backgroundColor = self.theme.primaryBackgroundColor;
    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.doneItem stp_setTheme:navBarTheme];
    self.tableView.allowsSelection = YES;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = self.theme.primaryBackgroundColor;
    if ([STPColorUtils colorIsBright:self.theme.primaryBackgroundColor]) {
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    } else {
        self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
    self.imageView.tintColor = self.theme.accentColor;
    for (UITableViewCell *cell in [self.tableView visibleCells]) {
        STPShippingMethodTableViewCell *shippingCell = (STPShippingMethodTableViewCell *)cell;
        [shippingCell setTheme:self.theme];
    }
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    return ([STPColorUtils colorIsBright:navBarTheme.secondaryBackgroundColor]
            ? UIStatusBarStyleDefault
            : UIStatusBarStyleLightContent);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    self.stp_navigationItemProxy.leftBarButtonItem = self.backItem;
    if (self.navigationController.navigationBar.translucent) {
        CGFloat insetTop = CGRectGetMaxY(self.navigationController.navigationBar.frame);
        self.tableView.contentInset = UIEdgeInsetsMake(insetTop, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    } else {
        self.tableView.contentInset = UIEdgeInsetsZero;
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    CGPoint offset = self.tableView.contentOffset;
    offset.y = -self.tableView.contentInset.top;
    self.tableView.contentOffset = offset;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)cancel:(__unused id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)done:(__unused id)sender {
    [self.delegate shippingMethodsViewController:self didFinishWithShippingMethod:self.selectedShippingMethod];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.shippingMethods.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPShippingMethodTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPShippingMethodCellReuseIdentifier forIndexPath:indexPath];
    PKShippingMethod *method = [self.shippingMethods stp_boundSafeObjectAtIndex:indexPath.row];
    cell.theme = self.theme;
    [cell setShippingMethod:method currency:self.currency];
    cell.selected = [method.identifier isEqualToString:self.selectedShippingMethod.identifier];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    return 57;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 27.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return tableView.sectionHeaderHeight;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(__unused NSInteger)section {
    UILabel *label = [UILabel new];
    label.font = self.theme.smallFont;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.firstLineHeadIndent = 15;
    NSDictionary *attributes = @{NSParagraphStyleAttributeName: style};
    label.textColor = self.theme.secondaryForegroundColor;
    label.attributedText = [[NSAttributedString alloc] initWithString:STPLocalizedString(@"Shipping Method", @"Label for shipping method form") attributes:attributes];
    return label;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    self.selectedShippingMethod = [self.shippingMethods stp_boundSafeObjectAtIndex:indexPath.row];
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationFade];
}

@end
