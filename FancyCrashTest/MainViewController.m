//
//  MainViewController.m
//  FancyCrashTest
//
//  Created by Wang Xiaolei on 3/26/14.
//  Copyright (c) 2014 Wang Xiaolei. All rights reserved.
//

#import "MainViewController.h"
#import "FancyCrash.h"

@interface MainViewController ()

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:
                                 [UIImage imageNamed:@"background"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [FancyCrash crash];
//    [FancyCrash crashWithEffect:kFancyCrashEffectBreakGlass1
//                  effectOptions:@{@"rows": @8, @"columns": @6}];
}

@end
