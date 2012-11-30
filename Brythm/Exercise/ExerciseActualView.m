//
//  ExerciseActualView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/16/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseActualView.h"

@implementation ExerciseActualView
@synthesize imageView;
@synthesize orgX;
@synthesize orgY;
@synthesize database;

#define PI 3.14159265358979323846
static inline float radians(double degrees) { return degrees * PI / 180; }

- (void)awakeFromNib{
    
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:0.0f];

    imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"BreathFeedbackCircle.png"]];
    imageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:imageView];
    orgX = imageView.center.x;
    orgY = imageView.center.y;
                                  
    // We need to correct this implementation align to the MVC model.
    // View should not have its controller.
    self.database = [BreathWearDatabase getDatabase];
    
    // TODO: change logic to measure the depth of breath
    minStretchValue = 1000;
    maxStretchValue = 0;
    
    stretchValue = self.database.stretchValue;
    if(stretchValue>0){
        if (stretchValue<minStretchValue){
            minStretchValue = stretchValue;
        }
        if (stretchValue>maxStretchValue){
            maxStretchValue = stretchValue;
        }
    }
    
    CGFloat size = 224;
    CGRect newFrame = CGRectMake(orgX-size/2, orgY-size/2, size, size);
    imageView.frame = newFrame;
    
    [NSTimer scheduledTimerWithTimeInterval:0.04f target:self selector:@selector(setNeedsDisplay) userInfo:nil  repeats:YES];
}

- (void)drawRect:(CGRect)rect {
    
    stretchValue = self.database.stretchValue;
    if(stretchValue>0){
        if (stretchValue<minStretchValue){
            minStretchValue = stretchValue;
        }
        if (stretchValue>maxStretchValue){
            maxStretchValue = stretchValue;
        }

        CGFloat orgSize = imageView.frame.size.width;
        CGFloat dstSize = ((float)(stretchValue-minStretchValue+1))/((float)(maxStretchValue-minStretchValue+1)) * 250.0f + 50.0f;
    
        CGFloat size = orgSize + (dstSize-orgSize)/30.0f + 1.0f;
        //NSLog(@"%d,%d,%d,%f,%f,%f",stretchValue,minStretchValue,maxStretchValue,orgSize,dstSize,size);
            
        CGRect newFrame = CGRectMake(orgX-size/2, orgY-size/2, size, size);
        imageView.frame = newFrame;
    }
}
@end
