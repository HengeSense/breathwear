//
//  ExerciseActualView.h
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BreathWearDatabase.h"

#define SIZE 0.35
#define SIZE_OFFSET 0.2
#define GUIDE_RATE_RATIO 0.8

@class BreathWearDatabase;

@interface ExerciseActualView : UIView{
    int stretchValue;
    int minStretchValue; // TODO: change logic to measure the depth of breath
    int maxStretchValue; // TODO: change logic to measure the depth of breath
}

@property (nonatomic, retain) UIImageView *imageView;
@property (strong, nonatomic) BreathWearDatabase *database;
@property float orgX;
@property float orgY;

@end
