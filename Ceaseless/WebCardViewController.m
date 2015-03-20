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
    [self formatCardView: self.webViewCard.cardView withShadowView:self.webViewCard.shadowView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSURL* url = [NSURL URLWithString: self.dataObject];
    [self.webViewCard.webView loadRequest: [NSURLRequest requestWithURL:url]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
