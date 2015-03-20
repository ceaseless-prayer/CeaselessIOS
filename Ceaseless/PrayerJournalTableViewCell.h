//
//  TableViewCell.h
//  Ceaseless
//
//  Created by Lori Hill on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PrayerJournalTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *notesContentView;
@property (weak, nonatomic) IBOutlet UIView *cellBackground;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;
@property (weak, nonatomic) IBOutlet UILabel *peopleTagged;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *text;

@end
