//
//  ExerciseViewController.h
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/8/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExerciseGuideView.h"
#import "ExerciseView.h"
#import "ExerciseDoneView.h"

@class BreathWearDatabase;
@class ExerciseView;
@class ExerciseDoneView;
@class BreathwearCalmPointController;

#define EXERCISE_DURATION 65.0
#define GAUGE_ORG_Y 300

@interface ExerciseViewController : UIViewController{
    bool isDone;
}

@property (strong, nonatomic) BreathWearDatabase *database;
@property (strong, retain) ExerciseView *exerciseView;
@property (strong, retain) ExerciseDoneView *exerciseDoneView;
@property (strong) NSTimer *exerciseTimer;
@property (strong, nonatomic) NSDate *startTime;

@property float baseline;

- (IBAction)startExercise:(id)sender;

@end
