//
//  PersonNotesTableViewCell.h
//  Ceaseless
//
//  Created by Lori Hill on 3/19/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PersonNotesTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *text;

@end
