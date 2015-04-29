//
//  ProgressViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 4/8/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "ProgressView.h"

@interface ProgressViewController : DataViewController
    @property (strong, nonatomic) IBOutlet ProgressView *progressView;
    - (IBAction)showMorePeople:(id)sender;
    - (IBAction) showAnnouncement:(id)sender;
    - (IBAction)showSubscribeToMailingList:(id)sender;
@end
