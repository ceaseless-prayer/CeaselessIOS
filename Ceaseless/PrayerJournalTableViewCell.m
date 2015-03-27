//
//  TableViewCell.m
//  Ceaseless
//
//  Created by Lori Hill on 3/13/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PrayerJournalTableViewCell.h"

@implementation PrayerJournalTableViewCell

- (void)awakeFromNib {
    // Initialization code
	self.cellBackground.layer.cornerRadius = 6.0f;
	self.topImageView.layer.cornerRadius = 6.0f;
	[self.topImageView setClipsToBounds:YES];
	self.bottomImageView.layer.cornerRadius = 6.0f;
	[self.bottomImageView setClipsToBounds:YES];

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
