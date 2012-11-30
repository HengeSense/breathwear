//
//  ExerciseBGView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseBGView.h"

@implementation ExerciseBGView

- (void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
}

- (void)drawRect:(CGRect)rect {
    
	CGRect parentViewBounds = self.bounds;
	CGFloat x = CGRectGetWidth(parentViewBounds) * 0.5;
	CGFloat y = CGRectGetHeight(parentViewBounds) * 0.45;
    CGFloat size = CGRectGetWidth(parentViewBounds) * 0.35;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColor (context, CGColorGetComponents( [[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1 ] CGColor]));
    CGContextAddEllipseInRect(context,CGRectMake(x-size, y-size, size*2, size*2));
    CGContextStrokePath(context);
        
}
@end
