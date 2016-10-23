//
//  CelebrationViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 10/22/16.
//  Copyright © 2016 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataViewController.h"
#import "CelebrationView.h"

@interface CelebrationViewController : DataViewController
@property (strong, nonatomic) IBOutlet CelebrationView *celebrationView;
- (IBAction)showMorePeople:(id)sender;
- (IBAction)shareProgress:(id)sender;

@end
