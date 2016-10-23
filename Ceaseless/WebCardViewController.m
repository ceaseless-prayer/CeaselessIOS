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
    Reachability *reach = [Reachability reachabilityForInternetConnection];
    if([reach currentReachabilityStatus] == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Internet Connection", nil) message:NSLocalizedString(@"Please connect to the internet to see this.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
        [alert show];
    }
    
    NSURL* url = [NSURL URLWithString: self.dataObject];
    [self.webCardView.webView loadRequest: [NSURLRequest requestWithURL:url]];
    [self formatCardView: self.webCardView.cardView withShadowView:self.webCardView.shadowView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.screenName = @"WebCardViewScreen";
}

- (void)viewWillDisppear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

@end
