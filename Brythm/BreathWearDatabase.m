//
//  BreathWearDatabase.m
//  TI-BLE-Demo
//
//  Created by Kenneth Jung on 12/24/11.
//  Copyright (c) 2011 ST alliance AS. All rights reserved.
//

#import "BreathWearDatabase.h"
#import "BreathWearRecord.h"
#import "BreathWearNotification.h"
#import "BreathWearActivityRecord.h"

// Added by Takehiro start
#import "BreathWearCalmPoint.h"
#import "BreathWearSelfReportQuestion.h"
// Added by Takehiro end

// Insert and retrieve records
// Records have four fields: raw data from sensor, breath rate, timestamp, and session id.  
// The last is a numeric uid.  
/*
 sessionid = number seconds since 1970 of start of session (defined as the time of connection to device)
 breathrate = floating point number
 sensor_value = int from stretch sensor
 timestamp = 
 */
static const char *INSERT_RATE_RECORD = "INSERT INTO breathrate (sessionid, breathrate, timestamp, sensor_value, baseline) VALUES(?, ?, ?, ?, ?)";
static const char *GET_RATE_RECORDS_QUERY = "SELECT sessionid, breathrate, timestamp, sensor_value, baseline FROM breathrate ORDER BY sessionid, timestamp ASC";
static const char *GET_RATE_RECORDS_FOR_SESSION_QUERY = "SELECT sessionid, breathrate, timestamp, sensor_value, baseline FROM breathrate WHERE sessionid = ? ORDER BY sessionid, timestamp ASC";
static const char *GET_RATE_RECORDS_AFTER_QUERY = "SELECT sessionid, breathrate, timestamp, sensor_value, baseline FROM breathrate WHERE timestamp > ? ORDER BY sessionid, timestamp ASC";
static const char *DELETE_RECORDS = "DELETE FROM breathrate";
static const char *GET_COUNT_RATE_RECORDS_BETWEEN_QUERY = "SELECT count(breathrate) FROM breathrate WHERE timestamp > ? AND timestamp < ?";
static const char *GET_RATES_BETWEEN_QUERY = "SELECT breathrate FROM breathrate WHERE timestamp > ? AND timestamp < ? ORDER BY timestamp ASC";

// We also want to record notifications...  Not sure yet what we want here - some timestamp and a type, maybe duration, messages?
static const char *INSERT_NOTIFICATION = "INSERT INTO notifications (sessionid, notification_type, start, end) VALUES(?, ?, ?, ?)";
static const char *GET_NOTIFICATIONS_QUERY = "SELECT sessionid, notification_type, start, end FROM notifications ORDER BY start ASC";
static const char *GET_NOTIFICATIONS_FOR_SESSION_QUERY = "SELECT sessionid, notification_type, start, end FROM notifications WHERE sessionid = ?  ORDER BY start ASC";
static const char *DELETE_NOTIFICATIONS = "DELETE FROM notifications";


static const char *INSERT_ACTIVITY = "INSERT INTO activity (date, activity) VALUES(?, ?)";
static const char *GET_ACTIVITIES = "SELECT date, activity FROM activity ORDER BY date ASC";
static const char *GET_ACTIVITIES_AFTER = "SELECT date, activity FROM activity WHERE date > ? ORDER BY date ASC";
static const char *DELETE_ACTIVITIES = "DELETE FROM activity";

// Added by Takehiro start
// CalmPoint
static const char *INSERT_CALMPOINT = "INSERT INTO calmpoints (date, calmpoint) VALUES(?, ?)";
static const char *UPDATE_CALMPOINT = "UPDATE calmpoints SET calmpoint = ? where date = ?";
static const char *GET_CALMPOINTS = "SELECT date, calmpoint FROM calmpoints ORDER BY date ASC";
static const char *GET_CALMPOINT_WITH_DATE = "SELECT date, calmpoint FROM calmpoints where date = ?";
static const char *GET_LAST_CALMPOINT = "SELECT date, calmpoint FROM calmpoints WHERE date = (SELECT MAX(date) FROM calmpoints)";
static const char *DELETE_CALMPOINTS = "DELETE FROM calmpoints";

// SelfReport
static const char *GET_SELFREPORT_QUESTION = "SELECT id, question, answer FROM selfreports WHERE id = ?";
static const char *GET_NUMBER_OF_SELFREPORT_QUESTION = "SELECT COUNT(id) FROM selfreports";
// Added by Takehiro end

#pragma mark STATIC PROCEDURES
static NSString *getTextColumnAsString(sqlite3_stmt *stmt, int col)
{
	char *str = (char *) sqlite3_column_text(stmt, col);
	NSString *retval = (str) ? [NSString stringWithUTF8String:str] : @"";
	return retval;
}

static NSNumber *getIntColumnAsNumber(sqlite3_stmt *stmt, int col)
{
	int intValue = sqlite3_column_int(stmt, col);
	return [NSNumber numberWithInt:intValue];
}

static NSNumber *getFloatColumnAsNumber(sqlite3_stmt *stmt, int col) 
{
	float floatValue = (float) sqlite3_column_double(stmt, col);
	return [NSNumber numberWithFloat:floatValue];
}

static int getIntColumn(sqlite3_stmt *stmt, int col)
{
	int intValue = sqlite3_column_int(stmt, col);
	return intValue;
}

static BOOL getIntColumnAsBool(sqlite3_stmt *stmt, int col)
{
	int intValue = sqlite3_column_int(stmt, col);
	return (intValue) ? YES : NO;
}

static double getDoubleColumn(sqlite3_stmt *stmt, int col)
{
    double value = (double)sqlite3_column_double(stmt, col);
    return value;
}

static float getFloatColumn(sqlite3_stmt *stmt, int col) 
{
	float floatValue = (float) sqlite3_column_double(stmt, col);
	return floatValue;
    
}


static BreathWearRecord *getRateFromStatement(sqlite3_stmt *sql_stmt) 
{

    int sessionid = getIntColumn(sql_stmt, 0);
    double breathRate = getDoubleColumn(sql_stmt, 1);
    int timestamp = getIntColumn(sql_stmt, 2);
    unsigned char sensor_value = (unsigned int) getIntColumn(sql_stmt, 3);
    float baseline = getFloatColumn(sql_stmt, 4);
    BreathWearRecord *record = [[BreathWearRecord alloc] initWithRate:breathRate 
                                                                 time:timestamp 
                                                              session:sessionid 
                                                               sensor:sensor_value
                                                             baseline:baseline ];
    return record;
}


static BreathWearNotification *getNotificationFromStatement(sqlite3_stmt *sql_stmt)
{
    int sessionid = getIntColumn(sql_stmt, 0);
    NSString *type = getTextColumnAsString(sql_stmt, 1);
    int start = getIntColumn(sql_stmt, 2);
    float length = getFloatColumn(sql_stmt, 3);
    BreathWearNotification *notification = [[BreathWearNotification alloc] initWithType:type 
                                                                                session:sessionid 
                                                                                  start:start 
                                                                               duration:length
                                                                                message:nil];
    return notification;
}

static BreathWearActivityRecord *getActivityRecordFromStatement(sqlite3_stmt *sql_stmt)
{
    BreathWearActivityRecord *record = [[BreathWearActivityRecord alloc] init];
    int timestamp = getIntColumn(sql_stmt, 0);
    record.timestamp = [NSDate dateWithTimeIntervalSince1970:timestamp];
    record.description = getTextColumnAsString(sql_stmt, 1);
    return record;
}

// Added by Takehiro start
// CalmPoint
static BreathWearCalmPoint *getCalmPointFromStatement(sqlite3_stmt *sql_stmt)
{
    int date = getIntColumn(sql_stmt, 0);
    float point = getFloatColumn(sql_stmt, 1);
    BreathWearCalmPoint *calmPoint = [[BreathWearCalmPoint alloc] initWithDate:date
                                                                    calmPoint:point];
    return calmPoint;    
}

//SelfReport
static BreathWearSelfReportQuestion *getSelfReportQuestionFromStatement(sqlite3_stmt *sql_stmt)
{
    int qid = getIntColumn(sql_stmt, 0);
    NSString *q = getTextColumnAsString(sql_stmt, 1);
    NSString *a = getTextColumnAsString(sql_stmt, 2);
    BreathWearSelfReportQuestion *selfReportQ = [[BreathWearSelfReportQuestion alloc] initWithQuestionId:qid question:q answer:a];
    
    return selfReportQ;    
}
// Added by Takehiro end

static BreathWearDatabase *_database_ = nil;


@implementation BreathWearDatabase

@synthesize db;
@synthesize currentBreathRate;
@synthesize stretchValue;

+ (BreathWearDatabase *)getDatabase
{
    if (_database_ == nil) {
        _database_ = [[BreathWearDatabase alloc] initWithDatabaseFile:@"breathwear.db"];
    }
    return _database_;
}

+ (void)closeDatabase
{
    if (_database_ != nil) {
        [_database_ close];
        _database_ = nil;
    }
}

- (id)initWithDatabaseFile:(NSString *)filename {
    if (self = [super init]) {
		if (filename == nil) return self;
        NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *dbFilePath = [documentDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", filename]];        
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:dbFilePath];
        if (fileExists == NO) {
            NSString *resourcesDir = [[NSBundle mainBundle] resourcePath];
            NSString *srcFilePath = [resourcesDir stringByAppendingPathComponent:filename];
            NSError *err;
            if ([[NSFileManager defaultManager] copyItemAtPath:srcFilePath toPath:dbFilePath error:&err] == NO) {
                NSLog(@"Error copying db file: %@", err);
            }
        }
        
		const char *c_file_path = [dbFilePath cStringUsingEncoding:NSASCIIStringEncoding];
		int rc = sqlite3_open(c_file_path, &db);
		if (rc) 
			NSLog(@"Error opening database file %@: %s", dbFilePath, sqlite3_errmsg(db));
		else 
			NSLog(@"Opened data base file = %@", dbFilePath);
	}
    
	return self;
}

- (void)close
{
    if (db)
        sqlite3_close(db);
}


- (void)insertRecord:(BreathWearRecord *)record
{
 	sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, INSERT_RATE_RECORD, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return;
	}

    sqlite3_bind_int(sql_stmt, 1, record.sessionid);
    sqlite3_bind_double(sql_stmt, 2, (double) record.breathRate);
    sqlite3_bind_double(sql_stmt, 3, record.timestamp);
    sqlite3_bind_int(sql_stmt, 4, (int) record.sensorValue);
    sqlite3_bind_double(sql_stmt, 5, (int) record.baselineRate);
	int success = sqlite3_step(sql_stmt);
	if (success == SQLITE_DONE) {
		//NSLog(@"Inserted new rate record!");
	} else {
		NSLog(@"Error inserting new rate record into db: %s", sqlite3_errmsg(db));
	}
	
	sqlite3_finalize(sql_stmt);
	return;   
}

- (NSArray *)getRecordsForSession:(int)sessionid;
{

    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_RATE_RECORDS_FOR_SESSION_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}

	sqlite3_bind_int(sql_stmt, 1, sessionid);

    NSMutableArray *records = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearRecord *record = getRateFromStatement(sql_stmt);
            [records addObject:record];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return records;
}

- (NSArray *)getRecords
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_RATE_RECORDS_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearRecord *record = getRateFromStatement(sql_stmt);
            [records addObject:record];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return records;    
}

- (NSArray *)getRecordsAfter:(float)timestamp
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_RATE_RECORDS_AFTER_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    sqlite3_bind_double(sql_stmt, 1, timestamp);
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearRecord *record = getRateFromStatement(sql_stmt);
            [records addObject:record];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return records;    
}

- (int)countRecordsBetween:(float)start and:(float)end 
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, GET_COUNT_RATE_RECORDS_BETWEEN_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return 0;
	}
    
    sqlite3_bind_double(sql_stmt, 1, start);
    sqlite3_bind_double(sql_stmt, 2, end);
    int count = 0;
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            count = getIntColumn(sql_stmt, 0);
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
    return count;  
    
}

- (void)getBreathRateBetween:(float)start and:(float)end in:(float *)data length:(int)length
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, GET_RATES_BETWEEN_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return;
	}
    
    sqlite3_bind_double(sql_stmt, 1, start);
    sqlite3_bind_double(sql_stmt, 2, end);

    int i = 0;
	int success;
	while ((success = sqlite3_step(sql_stmt)) && i < length) {
		if (success == SQLITE_ROW) {
            data[i++] = getFloatColumn(sql_stmt, 0);
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
    return;  

}



- (void)deleteRecords
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, DELETE_RECORDS, -1, &sql_stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
        return;
    }
    int success;
    if ((success = sqlite3_step(sql_stmt))) {
        NSLog(@"Deleted all records from database");
    } 
    sqlite3_finalize(sql_stmt);
    return;
}

- (NSArray *)getNotificationsForSession:(int)sessionid
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_NOTIFICATIONS_FOR_SESSION_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
	sqlite3_bind_int(sql_stmt, 1, sessionid);
    
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearNotification *notification = getNotificationFromStatement(sql_stmt);
            [notifications addObject:notification];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return notifications;
}

- (NSArray *)getNotifications
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_NOTIFICATIONS_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
        
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearNotification *notification = getNotificationFromStatement(sql_stmt);
            [notifications addObject:notification];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return notifications;
}


- (void)insertNotification:(BreathWearNotification *)notification
{
 	sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, INSERT_NOTIFICATION, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return;
	}
    const char *c_str_type = [notification.notificationType cStringUsingEncoding:NSASCIIStringEncoding];

    sqlite3_bind_int(sql_stmt, 1, notification.sessionid);
    sqlite3_bind_text(sql_stmt, 2, c_str_type, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(sql_stmt, 3, notification.startTimestamp);
    sqlite3_bind_double(sql_stmt, 4, notification.duration);
	int success = sqlite3_step(sql_stmt);
	if (success == SQLITE_DONE) {
		//NSLog(@"Inserted new rate record!");
	} else {
		NSLog(@"Error inserting new rate record into db: %s", sqlite3_errmsg(db));
	}
	
	sqlite3_finalize(sql_stmt);
	return;   
}

- (void)deleteNotifications
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, DELETE_NOTIFICATIONS, -1, &sql_stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
        return;
    }
    int success;
    if ((success = sqlite3_step(sql_stmt))) {
        NSLog(@"Deleted all notifications from database");
    } 
    sqlite3_finalize(sql_stmt);
    return;
}


+ (void)insertActivityRecord:(NSString *)recordString
{
    BreathWearDatabase *db = [BreathWearDatabase getDatabase];
    [db insertActivityRecord:recordString];
}

- (void)insertActivityRecord:(NSString *)recordString
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, INSERT_ACTIVITY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return;
	}

    NSDate *date = [NSDate date];
    int timestamp = (int) [date timeIntervalSince1970];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss a"];
    NSString *dateString = [formatter stringFromDate:date];
    recordString = [NSString stringWithFormat:@"%@\t%@", dateString, recordString];
    const char *c_record_str = [recordString cStringUsingEncoding:NSASCIIStringEncoding];
    sqlite3_bind_int(sql_stmt, 1, timestamp);
    sqlite3_bind_text(sql_stmt, 2, c_record_str, -1, SQLITE_TRANSIENT);
	int success = sqlite3_step(sql_stmt);
	if (success == SQLITE_DONE) {
		//NSLog(@"Inserted new activity record!");
	} else {
		NSLog(@"Error inserting new rate record into db: %s", sqlite3_errmsg(db));
	}
	
	sqlite3_finalize(sql_stmt);
	return;   
}

- (NSArray *)getActivityRecords
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_ACTIVITIES, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            BreathWearActivityRecord *record = getActivityRecordFromStatement(sql_stmt);
            [records addObject:record];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return records;
}

- (NSArray *)getActivityRecordsAfter:(float)timestamp
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_ACTIVITIES_AFTER, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    sqlite3_bind_double(sql_stmt, 1, timestamp);
    
    NSMutableArray *records = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            BreathWearActivityRecord *record = getActivityRecordFromStatement(sql_stmt);
            [records addObject:record];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return records;
}


- (void)deleteActivityRecords
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, DELETE_ACTIVITIES, -1, &sql_stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
        return;
    }
    int success;
    if ((success = sqlite3_step(sql_stmt))) {
        NSLog(@"Deleted all notifications from database");
    } 
    sqlite3_finalize(sql_stmt);
    return;
}

- (NSArray *)getRecordsArrayAfter:(float)timestamp
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    NSArray *records = [self getRecordsAfter:timestamp];
    for (BreathWearRecord *record in records) {
        NSArray *recordArray = [NSArray arrayWithObjects:[NSNumber numberWithInt:record.sessionid], 
                                [NSNumber numberWithDouble:record.timestamp], 
                                [NSNumber numberWithFloat:record.breathRate], 
                                [NSNumber numberWithInt:(int)record.sensorValue], 
                                [NSNumber numberWithInt:(int)record.baselineRate], 
                                nil];
        [retval addObject:recordArray];
    }
    return retval;
}

- (NSArray *)getActivityRecordsArrayAfter:(float)timestamp
{
    NSMutableArray *retval = [[NSMutableArray alloc] init];
    NSArray *activityRecords = [self getActivityRecordsAfter:timestamp];
    for (BreathWearActivityRecord *record in activityRecords) {
        NSArray *recordArray = [NSArray arrayWithObjects:record.description, 
                                [NSNumber numberWithInt:(int)[record.timestamp timeIntervalSince1970]], 
                                nil];
        [retval addObject:recordArray];
    }
    
    return retval;
}

// Added by Takehiro start
- (void)insertOrUpdateCalmPoint:(BreathWearCalmPoint *)calmPoint
{    
    int lastDate = self.getLastDateOfCalmPoint;
    int success;

    sqlite3_stmt *sql_stmt;
    if (calmPoint.date == lastDate){
        if (sqlite3_prepare_v2(db, UPDATE_CALMPOINT, -1, &sql_stmt, NULL) != SQLITE_OK) {
            NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
            return;
        }    
        sqlite3_bind_double(sql_stmt, 1, calmPoint.calmPoint);
        sqlite3_bind_int(sql_stmt, 2, calmPoint.date);
        success = sqlite3_step(sql_stmt);
        if (success == SQLITE_DONE) {
            //NSLog(@"Inserted new rate record!");
        } else {
            NSLog(@"Error inserting new rate record into db: %s", sqlite3_errmsg(db));
        }
    }else{
        if (sqlite3_prepare_v2(db, INSERT_CALMPOINT, -1, &sql_stmt, NULL) != SQLITE_OK) {
            NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
            return;
        }    
        sqlite3_bind_int(sql_stmt, 1, calmPoint.date);
        sqlite3_bind_double(sql_stmt, 2, calmPoint.calmPoint);
        success = sqlite3_step(sql_stmt);
        if (success == SQLITE_DONE) {
            //NSLog(@"Inserted new rate record!");
        } else {
            NSLog(@"Error inserting new rate record into db: %s", sqlite3_errmsg(db));
        }
    }
    
	sqlite3_finalize(sql_stmt);
	return;   

}

+ (void)insertOrUpdateCalmPoint:(BreathWearCalmPoint *)calmPoint
{
    BreathWearDatabase *db = [BreathWearDatabase getDatabase];
    [db insertOrUpdateCalmPoint:calmPoint];
}

- (int)getLastDateOfCalmPoint
{
    sqlite3_stmt *sql_stmt_pre;
	if (sqlite3_prepare_v2(db, GET_LAST_CALMPOINT, -1, &sql_stmt_pre, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
	}
    
    int success;
    BreathWearCalmPoint *lastCalmPoint;
    while((success = sqlite3_step(sql_stmt_pre))){
        if (success == SQLITE_ROW){
            lastCalmPoint = getCalmPointFromStatement(sql_stmt_pre);
        }else if (success == SQLITE_DONE){
            break;
        }
    }
    return lastCalmPoint.date;
}

+ (int)getLastDateOfCalmPoint
{
    BreathWearDatabase *db = [BreathWearDatabase getDatabase];
    return [db getLastDateOfCalmPoint];
}

- (BreathWearCalmPoint *)getCalmPointWithDate:(int)date{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_CALMPOINT_WITH_DATE, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    sqlite3_bind_int(sql_stmt, 1, date);
    
	int success;
    BreathWearCalmPoint *calmPoint;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            calmPoint = getCalmPointFromStatement(sql_stmt);
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return calmPoint;
}

- (NSArray *)getCalmPoints
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_CALMPOINTS, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    NSMutableArray *calmPoints = [[NSMutableArray alloc] init];
	int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
			BreathWearCalmPoint *calmPoint = getCalmPointFromStatement(sql_stmt);
            [calmPoints addObject:calmPoint];
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return calmPoints;
}

- (void)deleteCalmPoints
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, DELETE_CALMPOINTS, -1, &sql_stmt, NULL) != SQLITE_OK) {
        NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
        return;
    }
    int success;
    if ((success = sqlite3_step(sql_stmt))) {
        NSLog(@"Deleted all notifications from database");
    } 
    sqlite3_finalize(sql_stmt);
    return;
}

- (BreathWearSelfReportQuestion *)getSelfReportQuestionWithId:(int)id
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_SELFREPORT_QUESTION, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    sqlite3_bind_int(sql_stmt, 1, id);
    
	int success;
    BreathWearSelfReportQuestion *selfReportQ;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            selfReportQ = getSelfReportQuestionFromStatement(sql_stmt);
		} else if (success == SQLITE_DONE) {
			break;
		}
	}
    
	sqlite3_finalize(sql_stmt);
    return selfReportQ;
}

- (int)getNumberOfSelfReportQuestion
{
    sqlite3_stmt *sql_stmt;
	if (sqlite3_prepare_v2(db, GET_NUMBER_OF_SELFREPORT_QUESTION, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return 0;
	}
    
    int ret;
    int success;
	while ((success = sqlite3_step(sql_stmt))) {
		if (success == SQLITE_ROW) {
            ret = sqlite3_column_int(sql_stmt, 0);
		} else if (success == SQLITE_DONE) {
			break;
		}
	}

    sqlite3_finalize(sql_stmt);
    return ret;
}

// Added by Takehiro end

@end


