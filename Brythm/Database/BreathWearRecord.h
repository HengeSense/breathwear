//
//  BreathWearRecord.h
//  TI-BLE-Demo
//
//  Created by Kenneth Jung on 12/27/11.
//  Copyright (c) 2011 ST alliance AS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BreathWearRecord : NSObject {

    // Number of seconds from 1970 of start of the session
    int sessionid;

    // Number of seconds since start of session (i.e. session id)
    double timestamp;

    // Instantaneous breath rate reported by BreathRate class
    double breathRate;

    // Raw sensor value
    int sensorValue;
    
    // baseline for this measurement
    float baselineRate;
}

@property (readwrite) int sessionid;
@property (readwrite) double timestamp;
@property (readwrite) double breathRate;
@property (readwrite) int sensorValue;
@property (readwrite) float baselineRate;

- (id)initWithRate:(double)rate time:(double)time session:(int)session sensor:(int)sensor baseline:(float)baseline;

@end
