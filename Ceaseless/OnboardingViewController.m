//
//  OnboardingViewController.m
//  Ceaseless
//
//  Created by Wilbert Liu on 2/26/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import "OnboardingViewController.h"
#import "WelcomeCollectionViewCell.h"
#import "AppUtils.h"

@interface OnboardingViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark - Collection View Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    // Welcome
    if (indexPath.row == 0) {
        WelcomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"welcomeCell" forIndexPath:indexPath];
        return cell;
    }

    return nil;
}

#pragma mark - Collection View Flow Layout Delegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}

@end
