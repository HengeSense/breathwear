//
//  ExerciseView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/28/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseView.h"

@implementation ExerciseView
@synthesize calmPointLabel;
@synthesize mainView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"ExerciseView" owner:self options:nil];
        [self addSubview:mainView];
    }
    return self;
}

- (void)awakeFromNib {
    [[NSBundle mainBundle] loadNibNamed:@"ExerciseView" owner:self options:nil];
    [self addSubview:mainView];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
