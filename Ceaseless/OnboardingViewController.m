//
//  OnboardingViewController.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/26/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "OnboardingViewController.h"
#import "WelcomeCollectionViewCell.h"
#import "SetupContactCollectionViewCell.h"
#import "AppUtils.h"

@interface OnboardingViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SetupContactDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation OnboardingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIImage *ceaselessImage = [UIImage imageNamed:@"logo_main"];
    ceaselessImage = [ceaselessImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:ceaselessImage];

    [self.collectionView registerNib:[UINib nibWithNibName:@"WelcomeCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"welcomeCell"];
    [self.collectionView registerNib:[UINib nibWithNibName:@"SetupContactCollectionViewCell" bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:@"setupContactCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Easy way to adjust layout if user change the device orientation
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Collection View Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    // Welcome
    if (indexPath.row == 0) {
        WelcomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"welcomeCell" forIndexPath:indexPath];
        return cell;
    }

    // Setup contact
    if (indexPath.row == 1) {
        SetupContactCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"setupContactCell" forIndexPath:indexPath];
        cell.delegate = self;
        return cell;
    }

    return nil;
}

#pragma mark - Collection View Flow Layout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}

#pragma mark - Scroll View Delegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSInteger currentIndex = scrollView.contentOffset.x / scrollView.frame.size.width;

    // Disable scroll when reaching step 1 of 2, and so on
    if (currentIndex > 0) {
        self.collectionView.scrollEnabled = NO;
    }

    // Update page control
    self.pageControl.currentPage = currentIndex;
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidEndDecelerating:scrollView];
}

#pragma mark - Setup Contact Delegate

- (void)setupContactFinished {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:2 inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:YES];
}

@end
