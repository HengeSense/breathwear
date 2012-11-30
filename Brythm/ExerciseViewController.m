//
//  ExerciseViewController.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/8/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseViewController.h"
#import "BreathWearDatabase.h"
#import "BreathRate.h"
#import "BreathwearCalmPointController.h"
#import "BaselineRecord.h"

@interface ExerciseViewController()
- (void)exerciseTimeCheck:(NSTimer *)timer;
@end

@implementation ExerciseViewController
@synthesize database;
@synthesize exerciseView;
@synthesize exerciseDoneView;
@synthesize exerciseTimer;
@synthesize startTime;
@synthesize baseline;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    self.baseline = [BaselineRecord getCurrentBaseline];
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    self.database = [BreathWearDatabase getDatabase];
    self.baseline = [BaselineRecord getCurrentBaseline];
    [self.database insertActivityRecord:@"Exercise introduction showed"];

    isDone = false;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.baseline = [BaselineRecord getCurrentBaseline];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.exerciseTimer invalidate];
    [self.navigationController popViewControllerAnimated:YES];    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
}

- (void)viewDidUnload
{
    //[self setCalmPointLabel:nil];
    [super viewDidUnload];
    [self.exerciseTimer invalidate];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)startExercise:(id)sender {
    
    self.startTime = [NSDate date];
    self.exerciseTimer = [NSTimer scheduledTimerWithTimeInterval:(float)0.05
                                                          target:self 
                                                        selector:@selector(exerciseTimeCheck:) 
                                                        userInfo:nil 
                                                         repeats:YES];
    
    // Load ExerciseView
    CGRect applicationFrame = self.view.frame;
    exerciseView = [[ExerciseView alloc] initWithFrame:applicationFrame];
    self.view = exerciseView;
}

- (void)exerciseTimeCheck:(NSTimer *)timer
{
    NSDate *currentDate = [NSDate date];
    float timeDelta = (float) ([currentDate timeIntervalSince1970] - [self.startTime timeIntervalSince1970]);

    // isDone Check
    if (timeDelta > EXERCISE_DURATION){
        if (!isDone){

            CGRect applicationFrame = self.view.frame;
            exerciseDoneView = [[ExerciseDoneView alloc] initWithFrame:applicationFrame];
            self.view = exerciseDoneView;

            isDone = true;
        }
        [self.exerciseTimer invalidate];
    }
}
@end
