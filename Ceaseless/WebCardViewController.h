//
//  WebCardViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataViewController.h"
#import "WebCardView.h"
#import "Reachability.h"

@interface WebCardViewController : DataViewController
    @property (strong, nonatomic) IBOutlet WebCardView *webCardView;
@end
