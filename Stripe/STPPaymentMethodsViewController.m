//
//  STPSourceListViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentMethodsViewController.h"
#import "STPBackendAPIAdapter.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPCard.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UIViewController+Stripe_ParentViewController.h"
#import "STPPaymentCardEntryViewController.h"
#import "STPCardPaymentMethod.h"
#import "STPPaymentContext.h"
#import "UIColor+Stripe.h"
#import "UIFont+Stripe.h"
#import "UIImage+Stripe.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";
static NSInteger STPPaymentMethodCardListSection = 0;
static NSInteger STPPaymentMethodAddCardSection = 1;

@interface STPPaymentMethodsViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic)STPPaymentContext *paymentContext;
@property(nonatomic, copy)STPPaymentMethodSelectionBlock onSelection;

@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic)BOOL loading;

@end

@implementation STPPaymentMethodsViewController

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext
                           onSelection:(STPPaymentMethodSelectionBlock)onSelection {
    self = [super init];
    if (self) {
        _paymentContext = paymentContext;
        _onSelection = onSelection;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.view.backgroundColor = [UIColor stp_backgroundGreyColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    tableView.sectionHeaderHeight = 40;
    tableView.separatorInset = UIEdgeInsetsMake(0, 18, 0, 0);
    tableView.tintColor = [UIColor stp_linkBlueColor];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[UIImage stp_largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    self.tableView.tableHeaderView = cardImageView;
    
    self.navigationItem.title = NSLocalizedString(@"Choose Payment", nil);
    [self.paymentContext performInitialLoad];
    [self.paymentContext onSuccess:^{
        [UIView animateWithDuration:0.2 animations:^{
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    }];
    self.loading = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    NSDictionary *titleTextAttributes = @{NSFontAttributeName:[UIFont stp_navigationBarFont]};
    self.navigationController.navigationBar.titleTextAttributes = titleTextAttributes;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    CGFloat baseInset = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    self.tableView.contentInset = UIEdgeInsetsMake(baseInset + self.tableView.sectionHeaderHeight, 0, 0, 0);
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    if (section == STPPaymentMethodCardListSection) {
        return self.paymentContext.paymentMethods.count;
    } else if (section == STPPaymentMethodAddCardSection) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = self.paymentContext.paymentMethods[indexPath.row];
        cell.textLabel.text = paymentMethod.label;
        cell.imageView.image = paymentMethod.image;
        if ([paymentMethod isEqual:self.paymentContext.selectedPaymentMethod]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            cell.textLabel.textColor = [UIColor stp_linkBlueColor];
        }
        else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.textLabel.textColor = [UIColor stp_darkTextColor];
        }
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        cell.textLabel.textColor = [UIColor stp_linkBlueColor];
        cell.imageView.image = [UIImage stp_addIcon];
        cell.textLabel.text = NSLocalizedString(@"Add New Card...", nil);
    }
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    return cell;
}

- (void)tableView:(__unused UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == STPPaymentMethodCardListSection) {
        id<STPPaymentMethod> paymentMethod = [self.paymentContext.paymentMethods stp_boundSafeObjectAtIndex:indexPath.row];
        
        NSInteger currentIndex = [self.paymentContext.paymentMethods indexOfObject:self.paymentContext.selectedPaymentMethod];
        NSInteger newIndex = [self.paymentContext.paymentMethods indexOfObject:paymentMethod];
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:currentIndex inSection:STPPaymentMethodCardListSection];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:newIndex inSection:STPPaymentMethodCardListSection];
        [self.tableView reloadRowsAtIndexPaths:@[oldIndexPath, newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        
        [self.paymentContext selectPaymentMethod:paymentMethod];
        [self finishWithPaymentMethod:paymentMethod];
    } else if (indexPath.section == STPPaymentMethodAddCardSection) {
        __weak typeof(self) weakself = self;
        BOOL useNavigationTransition = [self stp_isTopNavigationController];
        STPPaymentCardEntryViewController *paymentCardViewController;
        paymentCardViewController = [[STPPaymentCardEntryViewController alloc] initWithAPIClient:self.paymentContext.apiClient completion:^(STPToken *token, STPErrorBlock tokenCompletion) {
            if (token) {
                [self.paymentContext addToken:token completion:^(id<STPPaymentMethod> paymentMethod, NSError *error) {
                    if (error) {
                        tokenCompletion(error);
                    } else {
                        [weakself.paymentContext selectPaymentMethod:paymentMethod];
                        [weakself.tableView reloadData];
                        if (useNavigationTransition) {
                            [weakself.navigationController stp_popViewControllerAnimated:YES completion:^{
                                [weakself finishWithPaymentMethod:paymentMethod];
                                tokenCompletion(nil);
                            }];
                        } else {
                            [weakself dismissViewControllerAnimated:YES completion:^{
                                [weakself finishWithPaymentMethod:paymentMethod];
                                tokenCompletion(nil);
                            }];
                        }
                    }
                }];
            } else {
                if (useNavigationTransition) {
                    [weakself.navigationController stp_popViewControllerAnimated:YES completion:^{
                        tokenCompletion(nil);
                    }];
                } else {
                    [weakself dismissViewControllerAnimated:YES completion:^{
                        tokenCompletion(nil);
                    }];
                }
            }
        }];
        if (useNavigationTransition) {
            [self.navigationController pushViewController:paymentCardViewController animated:YES];
        } else {
            [self presentViewController:paymentCardViewController animated:YES completion:nil];
        }
    }
}

- (void)finishWithPaymentMethod:(id<STPPaymentMethod>)paymentMethod {
    if (self.onSelection) {
        self.onSelection(paymentMethod);
        self.onSelection = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return tableView.sectionHeaderHeight;
    }
    return tableView.sectionHeaderHeight / 2;
}

@end
