//
//  DataViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonView.h"

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *cardView;
@property (strong, nonatomic) PersonView *personView;
@property (strong, nonatomic) id dataObject;

@end
