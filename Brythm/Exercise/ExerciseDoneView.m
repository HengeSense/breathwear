//
//  ExerciseDoneView.m
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/29/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import "ExerciseDoneView.h"

@implementation ExerciseDoneView
@synthesize mainView;
@synthesize calmPointLabel;
@synthesize totalCalmPointLabel;
@synthesize congratsLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:@"ExerciseDoneView" owner:self options:nil];
        [self addSubview:mainView];
    }
    return self;
}

- (void)awakeFromNib {
    [[NSBundle mainBundle] loadNibNamed:@"ExerciseDoneView" owner:self options:nil];
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
