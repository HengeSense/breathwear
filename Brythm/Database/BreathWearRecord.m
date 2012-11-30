//
//  BreathWearRecord.m
//  TI-BLE-Demo
//
//  Created by Kenneth Jung on 12/27/11.
//  Copyright (c) 2011 ST alliance AS. All rights reserved.
//

#import "BreathWearRecord.h"

@implementation BreathWearRecord

@synthesize breathRate;
@synthesize sessionid;
@synthesize sensorValue;
@synthesize timestamp;
@synthesize baselineRate;


- (id)initWithRate:(float)rate time:(double)time session:(int)session sensor:(int)sensor baseline:(float)baseline
{
    if (self = [super init]) {
        breathRate = rate;
        sessionid = session;
        sensorValue = sensor;
        timestamp = time;
        baselineRate = baseline;
    }
    return self;
}

- (NSString *)description
{
    NSString *retval = [NSString stringWithFormat:@"%d\t%.2f\t%.4f\t%u\t%.2f", sessionid, timestamp, breathRate, (int)sensorValue, baselineRate];
    return retval;
}

@end
