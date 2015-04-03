//
//  BaseTableViewController.m
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseTableViewController.h"

@interface BaseTableViewController ()

@end

@implementation BaseTableViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.accentColor = kColorGreen;
    }
    return self;
}

- (void)loadView
{
    [super loadView];

    self.navigationController.navigationBarHidden = NO;

    [self setCustomTitleViewWithText:self.title];
    [self addBackButton];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [_tableView.backgroundView removeFromSuperview];
    _tableView.backgroundView = nil;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];    // Remove extra separators from tableview
    [self.view addSubview:_tableView];

    [self setupSearch];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Make the nav bar and search bar look like they are connected as one.

    [self.navigationController.navigationBar setBackgroundImage:[_accentColor asImage] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];
    self.navigationController.navigationBar.translucent = YES;     // Makes search bar show up below nav bar.
    if ([self.navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)])
        self.navigationController.navigationBar.barTintColor = _accentColor;
    else
        self.navigationController.navigationBar.tintColor = _accentColor;
}

- (void)viewDidLayoutSubviews
{
    _tableView.frame = R(0, 0, self.view.width, self.view.height);
    _tableView.contentInset = UIEdgeInsetsMake(64 + CGRectGetHeight(_searchBar.bounds), 0, 0, 0);
}

- (void)setupSearch
{
    self.searchBar = [[UISearchBar alloc] init];
    _searchBar.delegate = self;
    _searchBar.frame = R(0, 64, CGRectGetWidth(self.view.bounds), 44 * IdiomScale());
    _searchBar.placeholder = @"Search";
    _searchBar.showsCancelButton = NO;
    _searchBar.backgroundColor = _accentColor;
    _searchBar.backgroundImage = [_accentColor asImage];    // Make it look like the nav bar

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        if ([_searchBar respondsToSelector:@selector(setBarTintColor:)]) {
            _searchBar.barTintColor = _accentColor;
        }

        UITextField *textField = [_searchBar valueForKey:@"_searchField"];
        textField.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        textField.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.85];
        if ([textField respondsToSelector:@selector(setTintColor:)])
            textField.tintColor = kColorPink;
        if ([textField respondsToSelector:@selector(setAttributedPlaceholder:)]) {
            UIColor *color = [UIColor lightTextColor];
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_searchBar.placeholder attributes:@{NSForegroundColorAttributeName: color}];
        }
        textField.font = [UIFont fontWithName:kCustomFontName size:15];

        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{ UITextAttributeTextColor: [_accentColor darker], UITextAttributeFont: textField.font } forState:UIControlStateNormal];

        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{ UITextAttributeTextColor: [UIColor blackColor], UITextAttributeFont: textField.font } forState:UIControlStateHighlighted];
    }

    [self.view addSubview:_searchBar];

    self.searchController = [[UISearchDisplayController alloc] initWithSearchBar:_searchBar contentsController:self];
    _searchController.delegate = self;
    _searchController.searchResultsDataSource = self;
    _searchController.searchResultsDelegate = self;

    if ([_searchController.searchResultsTableView respondsToSelector:@selector(setSeparatorInset:)]) {
        _searchController.searchResultsTableView.separatorInset = UIEdgeInsetsZero;
    }

    _searchController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _searchController.searchResultsTableView.backgroundColor = kColorDarkBrown;
    _searchController.searchResultsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];    // Remove extra separators from tableview
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return _searchController.isActive ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.4 animations:^{
        _searchBar.frame = R(0, 20, CGRectGetWidth(self.view.bounds), 20 + 44 * IdiomScale());
    }];
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    [UIView animateWithDuration:0.4 animations:^{
        _searchBar.frame = R(0, 64, CGRectGetWidth(self.view.bounds), 44 * IdiomScale());
    }];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self updateMatchesForSearchString:searchString];
    return YES;
}

- (void)updateMatchesForSearchString:(NSString *)searchString
{
    // nop
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    [self.searchController setActive:NO animated:YES];
}

@end
