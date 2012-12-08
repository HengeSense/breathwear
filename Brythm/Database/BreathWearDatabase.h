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

@interface BreathWearDatabase : NSObject {
    sqlite3 *db;
    
}

@property (readonly) sqlite3 *db;
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
- (NSArray *)getBreathRateBetween:(float)start and:(float)end;
- (void)deleteRecords;

- (NSArray *)getRecordsArrayAfter:(float)timestamp;

@end