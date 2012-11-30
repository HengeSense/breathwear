//
//  ExerciseGuideView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseGuideView.h"

@implementation ExerciseGuideView
@synthesize controller;
@synthesize baseline;
@synthesize startTime;

#define PI 3.14159265358979323846
static inline float radians(double degrees) { return degrees * PI / 180; }

- (void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    
    [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(setNeedsDisplay) userInfo:nil  repeats:YES];
    
    self.startTime = [[NSDate date] timeIntervalSince1970];

    // We need to correct this implementation align to the MVC model.
    // View should not have its controller.
    self.controller = [[ExerciseViewController alloc] init];
    self.baseline = controller.baseline;

}

- (void)drawRect:(CGRect)rect {
    
    double timeProgress = (double)([[NSDate date] timeIntervalSince1970] - self.startTime);
   
    float size = pow((sin(radians(timeProgress*6.0*self.baseline*GUIDE_RATE_RATIO))+1.0)/2.0,1.2)*(SIZE-SIZE_OFFSET) + SIZE_OFFSET;
    
	CGRect parentViewBounds = self.bounds;
	CGFloat x = CGRectGetWidth(parentViewBounds) * 0.5;
	CGFloat y = CGRectGetHeight(parentViewBounds) * 0.45;
    CGFloat circleSize = CGRectGetWidth(parentViewBounds) * size;
    CGFloat lineWidth = 2;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context,lineWidth);
    CGContextSetStrokeColor (context, CGColorGetComponents( [[UIColor colorWithRed:0.2 green:0.5 blue:0.8 alpha:1 ] CGColor]));
    CGContextAddEllipseInRect(context,CGRectMake(x-circleSize, y-circleSize, circleSize*2, circleSize*2));
    CGContextStrokePath(context);
    
}
@end
