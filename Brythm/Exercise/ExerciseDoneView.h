//
//  ExerciseDoneView.h
//  TI-BLE-Demo
//
//  Created by Takehiro Hagiwara on 3/29/12.
//  Copyright (c) 2012 ST alliance AS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExerciseDoneView : UIView
@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (weak, nonatomic) IBOutlet UILabel *calmPointLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalCalmPointLabel;
@property (weak, nonatomic) IBOutlet UILabel *congratsLabel;

@end
