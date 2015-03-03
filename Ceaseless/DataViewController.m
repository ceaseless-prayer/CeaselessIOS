//
//  DataViewController.m
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "Person.h"

@interface DataViewController ()

@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	Person *person = self.dataObject;
	self.dataLabel.text = [NSString stringWithFormat: @"%@ %@", person.firstName, person.lastName];
	self.imageview.image = person.profileImage;
//	let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
//  let blurView = UIVisualEffectView(effect: blurEffect)
//  blurView.frame = myFrame
//  self.view.addSubview(blurView)
}

@end
