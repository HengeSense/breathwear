//
//  ExerciseGuideView.h
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExerciseViewController.h"

#define SIZE 0.35
#define SIZE_OFFSET 0.2
#define GUIDE_RATE_RATIO 0.8

@class ExerciseViewController;

@interface ExerciseGuideView : UIView

@property (strong, nonatomic) ExerciseViewController *controller;
@property float baseline;
@property NSTimeInterval startTime;

@end
