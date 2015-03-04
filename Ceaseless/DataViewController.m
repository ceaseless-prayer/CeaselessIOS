//
//  DataViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "Person.h"
#import "PersonView.h"

@interface DataViewController ()

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
	self.personView = [PersonView alloc];
	self.personView = [[[NSBundle mainBundle] loadNibNamed:@"PersonView" owner:self options:nil] lastObject];
	NSLog (@"count %lu", (unsigned long)[self.personView.subviews count]);
	[self.cardView addSubview: self.personView];

	[self.personView setTranslatesAutoresizingMaskIntoConstraints:NO];

	[self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
														  attribute:NSLayoutAttributeTop
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.cardView
														  attribute:NSLayoutAttributeTop
														 multiplier:1.0
														   constant:0.0]];

	[self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
														  attribute:NSLayoutAttributeLeading
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.cardView
														  attribute:NSLayoutAttributeLeading
														 multiplier:1.0
														   constant:0.0]];

	[self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
														  attribute:NSLayoutAttributeBottom
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.cardView
														  attribute:NSLayoutAttributeBottom
														 multiplier:1.0
														   constant:0.0]];

	[self.cardView addConstraint:[NSLayoutConstraint constraintWithItem:self.personView
														  attribute:NSLayoutAttributeTrailing
														  relatedBy:NSLayoutRelationEqual
															 toItem:self.cardView
														  attribute:NSLayoutAttributeTrailing
														 multiplier:1.0
														   constant:0.0]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	Person *person = self.dataObject;
	self.personView.nameLabel.text = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
	self.personView.personImageView.image = person.profileImage;

//	let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//  let blurView = UIVisualEffectView(effect: blurEffect)
//  blurView.frame = myFrame
//  self.view.addSubview(blurView)
}

@end
