//
//  MainExerciseViewController.m
//  Brythm
//
//  Created by Cassidy Robert Coyote Saenz on 11/29/12.
//  Copyright (c) 2012 Cassidy Robert Coyote Saenz. All rights reserved.
//

#import "MainExerciseViewController.h"
#import "ExerciseViewController.h"

@interface MainExerciseViewController ()

@end

@implementation MainExerciseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)startExercise
{
    ExerciseViewController *vc = [[ExerciseViewController alloc] initWithNibName:@"ExerciseViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
