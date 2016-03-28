//
//  STPSourceListViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSourceListViewController.h"
#import "STPSourceProvider.h"
#import "STPSourceCell.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPCard.h"
#import "NSArray+Stripe_BoundSafe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "STPPaymentCardEntryViewController.h"

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";

@interface STPSourceListViewController()<UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, weak)id<STPSourceListViewControllerDelegate> delegate;
@property(nonatomic)id<STPSourceProvider> sourceProvider;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIBarButtonItem *addButton;
@property(nonatomic)BOOL loading;

@end

@implementation STPSourceListViewController

- (nonnull instancetype)initWithSourceProvider:(nonnull id<STPSourceProvider>)sourceProvider
                                      delegate:(nonnull id<STPSourceListViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _sourceProvider = sourceProvider;
        _delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPSourceCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    self.tableView = tableView;
    [self.view addSubview:tableView];

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
    self.addButton = addButton;
    self.navigationItem.rightBarButtonItem = addButton;

    self.loading = YES;
    [self.sourceProvider retrieveSources:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, __unused NSError * _Nullable error) {
        self.loading = NO;
        if (error) {
            NSAssert(NO, @"TODO");
            return;
        }
        [self.tableView reloadData];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

- (void)reload {
    [self.tableView reloadData];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    self.addButton.enabled = !loading;
}

- (void)addSource:(__unused id)sender {
    [self.delegate sourceListViewControllerDidTapAddButton:self];
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.sourceProvider.sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    id<STPSource> source = self.sourceProvider.sources[indexPath.row];
    BOOL selected = source == self.sourceProvider.selectedSource;
    [cell configureWithSource:source selected:selected];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<STPSource> source = [self.sourceProvider.sources stp_boundSafeObjectAtIndex:indexPath.row];
    [self.delegate sourceListViewController:self didSelectSource:source];
}

@end
