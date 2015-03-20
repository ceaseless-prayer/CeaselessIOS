//
//  WebCardViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "WebCardViewController.h"

@interface WebCardViewController ()

@end

@implementation WebCardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL* url = [NSURL URLWithString: self.dataObject];
    [self.webCardView.webView loadRequest: [NSURLRequest requestWithURL:url]];
    [self formatCardView: self.webCardView.cardView withShadowView:self.webCardView.shadowView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
