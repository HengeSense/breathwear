//
//  ExerciseTimerView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseTimerView.h"

@implementation ExerciseTimerView

#define PI 3.14159265358979323846
static inline float radians(double degrees) { return degrees * PI / 180; }

@synthesize p_start;
@synthesize p_end;
@synthesize startTime;

-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];

    [NSTimer scheduledTimerWithTimeInterval:0.05f target:self selector:@selector(setNeedsDisplay) userInfo:nil  repeats:YES];
    
    self.startTime = [[NSDate date] timeIntervalSince1970];
    self.p_start = OFFSET;
    
}

- (void)drawRect:(CGRect)rect {
    
    double timeProgress = (double)([[NSDate date] timeIntervalSince1970] - self.startTime);
    if (timeProgress < DURATION_AT_START_POINT){
        return;
    }
    timeProgress -= DURATION_AT_START_POINT;

	CGRect parentViewBounds = self.bounds;
	CGFloat x = CGRectGetWidth(parentViewBounds) * 0.5;
	CGFloat y = CGRectGetHeight(parentViewBounds) * 0.45;
    CGFloat size = CGRectGetWidth(parentViewBounds) * 0.35;
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
	self.p_end = p_start + 360.0 * timeProgress / EXERCISE_DURATION;
    
	CGContextSetFillColor(context, CGColorGetComponents( [[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1 ] CGColor]));
	CGContextMoveToPoint(context, x, y);     
    CGContextAddArc(context, x, y, size, radians(self.p_start), radians(self.p_end), 0); 
    CGContextClosePath(context); 
    CGContextFillPath(context);
}

@end
