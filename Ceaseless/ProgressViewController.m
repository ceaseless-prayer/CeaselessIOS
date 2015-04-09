//
//  ProgressViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 4/8/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ProgressViewController.h"
#import "AppUtils.h"

@interface ProgressViewController ()

@end

@implementation ProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    float progress = [((NSNumber *) self.dataObject) floatValue];
    self.progressView.backgroundImageView.image = [AppUtils getDynamicBackgroundImage];
    [self.progressView.progressBar setProgress:progress animated:YES];
    [self formatCardView: self.progressView.cardView withShadowView:self.progressView.shadowView];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
