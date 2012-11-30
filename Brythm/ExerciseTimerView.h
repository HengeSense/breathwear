//
//  ExerciseTimerView.h
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import <UIKit/UIKit.h>
#define EXERCISE_DURATION 60.0
#define DURATION_AT_START_POINT 5.0
#define OFFSET -90.0

@interface ExerciseTimerView : UIView

@property double p_start;
@property double p_end;
@property NSTimeInterval startTime;

@end
