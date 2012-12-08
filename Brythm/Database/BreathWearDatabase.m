//
//  BreathWearDatabase.m
//  TI-BLE-Demo
//
//  Created by Kenneth Jung on 12/24/11.
//  Copyright (c) 2011 ST alliance AS. All rights reserved.
//

#import "BreathWearDatabase.h"
#import "BreathWearRecord.h"

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
static const char *GET_COUNT_RATE_RECORDS_BETWEEN_QUERY = "SELECT count(breathrate) FROM breathrate WHERE timestamp > ? AND timestamp < ? ORDER BY sessionid, timestamp ASC";
static const char *GET_RATES_BETWEEN_QUERY = "SELECT breathrate FROM breathrate WHERE timestamp > ? AND timestamp < ? ORDER BY timestamp ASC";

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
    double timestamp = getDoubleColumn(sql_stmt, 2);
    unsigned char sensor_value = (unsigned int) getIntColumn(sql_stmt, 3);
    float baseline = getFloatColumn(sql_stmt, 4);
    BreathWearRecord *record = [[BreathWearRecord alloc] initWithRate:breathRate 
                                                                 time:timestamp 
                                                              session:sessionid 
                                                               sensor:sensor_value
                                                             baseline:baseline ];
    return record;
}

static BreathWearDatabase *_database_ = nil;


@implementation BreathWearDatabase

@synthesize db;
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
                //NSLog(@"Error copying db file: %@", err);
            }
        }
        
        dbFilePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:filename];
        
		const char *c_file_path = [dbFilePath cStringUsingEncoding:NSASCIIStringEncoding];
		int rc = sqlite3_open(c_file_path, &db);
		if (rc) {
			//NSLog(@"Error opening database file %@: %s", dbFilePath, sqlite3_errmsg(db));
		} else {
			//NSLog(@"Opened data base file = %@", dbFilePath);
        }
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

- (NSArray *)getBreathRateBetween:(float)start and:(float)end
{
    sqlite3_stmt *sql_stmt;
    if (sqlite3_prepare_v2(db, GET_RATES_BETWEEN_QUERY, -1, &sql_stmt, NULL) != SQLITE_OK) {
		NSLog(@"Error preparing SQL: %s", sqlite3_errmsg(db));
		return nil;
	}
    
    sqlite3_bind_double(sql_stmt, 1, start);
    sqlite3_bind_double(sql_stmt, 2, end);
    
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

@end


