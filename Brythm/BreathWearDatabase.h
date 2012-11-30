//
//  BreathWearDatabase.h
//  TI-BLE-Demo
//
//  Created by Kenneth Jung on 12/24/11.
//  Copyright (c) 2011 ST alliance AS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@class BreathWearRecord;
@class BreathWearNotification;

// Added by Takehiro start
@class BreathWearCalmPoint;
@class BreathWearSelfReportQuestion;
// Added by Takehiro end

@interface BreathWearDatabase : NSObject {
    sqlite3 *db;
    
}

@property (readonly) sqlite3 *db;
@property float currentBreathRate;
@property int stretchValue;

+ (BreathWearDatabase *)getDatabase;
+ (void)closeDatabase;
- (id)initWithDatabaseFile:(NSString *)filename;
- (void)close;
- (void)insertRecord:(BreathWearRecord *)record;
- (NSArray *)getRecordsForSession:(int)sessionid;
- (NSArray *)getRecords;
- (NSArray *)getRecordsAfter:(float)timestamp;
- (int)countRecordsBetween:(float)start and:(float)end;
- (void)getBreathRateBetween:(float)start and:(float)end in:(float *)data length:(int)length;
- (void)deleteRecords;

- (NSArray *)getNotificationsForSession:(int)sessionid;
- (NSArray *)getNotifications;
- (void)insertNotification:(BreathWearNotification *)notification;
- (void)deleteNotifications;

- (void)insertActivityRecord:(NSString *)recordString;
- (NSArray *)getActivityRecords;
- (NSArray *)getActivityRecordsAfter:(float)timestamp;
- (void)deleteActivityRecords;

// Added by Takehiro start
- (void)insertOrUpdateCalmPoint:(BreathWearCalmPoint *)calmPoint;
+ (void)insertOrUpdateCalmPoint:(BreathWearCalmPoint *)calmPoint;
- (NSArray *)getCalmPoints;
- (BreathWearCalmPoint *)getCalmPointWithDate:(int)date;
- (int)getLastDateOfCalmPoint;
+ (int)getLastDateOfCalmPoint;
- (void)deleteCalmPoints;

- (BreathWearSelfReportQuestion *)getSelfReportQuestionWithId:(int)id;
- (int)getNumberOfSelfReportQuestion;

// Added by Takehiro end

+ (void)insertActivityRecord:(NSString *)recordString;

- (NSArray *)getRecordsArrayAfter:(float)timestamp;
- (NSArray *)getActivityRecordsArrayAfter:(float)timestamp;

@end