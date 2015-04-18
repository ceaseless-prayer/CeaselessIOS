//
//  ContactsListTableViewCell.m
//  Ceaseless
//
//  Created by Lori Hill on 3/24/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ContactsListTableViewCell.h"

@implementation ContactsListTableViewCell

- (void)awakeFromNib {
    // Initialization code
	self.personImageView.layer.cornerRadius = 6.0f;
	[self.personImageView setClipsToBounds:YES];
	self.placeholderLabel.layer.cornerRadius = 6.0f;
	[self.placeholderLabel setClipsToBounds:YES];
}

- (IBAction)favoriteChanged:(id)sender {
	self.onFavoriteChange(self);
}
@end
