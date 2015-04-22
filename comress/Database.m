//
//  Database.m
//  comress
//
//  Created by Diffy Romano on 29/1/15.
//  Copyright (c) 2015 Combuilder. All rights reserved.
//

#import "Database.h"

static const int newDatabaseVersion = 2; //this database version is incremented everytime the database version is updated

@implementation Database

@synthesize initializingComplete,userBlocksInitComplete,allPostWasSeen;


+(instancetype)sharedMyDbManager {
    static id sharedMyDbManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyDbManager = [[self alloc] init];
    });
    return sharedMyDbManager;
}

-(id)init {
    if (self = [super init]) {
        initializingComplete = 0;
        userBlocksInitComplete = 0;
        allPostWasSeen = YES;
        
        [self copyDbToDocumentsDir];
        
        _databaseQ = [[FMDatabaseQueue alloc] initWithPath:self.dbPath];
        
        [self createClient];
        
        [self createUser];
        
        [self createAfManager];
        
        [self createDeviceToken];
        
    }
    return self;
}

- (void)createClient
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from client"];
        while ([rs next]) {
            _clientDictionary = [rs resultDictionary];
        }
    }];
    
}

- (void)createUser
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs = [db executeQuery:@"select * from users where is_active = ?",[NSNumber numberWithInt:1]];
        while ([rs next]) {
            _userDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createDeviceToken
{
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rs;
        
        rs  = [db executeQuery:@"select * from device_token"];
        while ([rs next]) {
            _deviceTokenDictionary = [rs resultDictionary];
        }
    }];
}

- (void)createAfManager
{
//    _api_url = @"http://comresstest.selfip.com/ComressMWCF/";
//    _domain = @"http://comresstest.selfip.com/";
    
    _api_url = [NSString stringWithFormat:@"%@%@",[_clientDictionary valueForKey:@"api_url"],app_path];
    _domain = [_clientDictionary valueForKey:@"api_url"];
    
    DDLogVerbose(@"session id: %@",[_clientDictionary valueForKey:@"user_guid"]);
    
    _AfManager = [AFHTTPRequestOperationManager manager];
    _AfManager.requestSerializer = [AFJSONRequestSerializer serializer];
    _AfManager.responseSerializer = [AFJSONResponseSerializer serializer];
    
    if([_clientDictionary valueForKey:@"user_guid"] != [NSNull null])
        [_AfManager.requestSerializer setValue:[_clientDictionary valueForKey:@"user_guid"] forHTTPHeaderField:@"ComSessionId"];
    
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    policy.allowInvalidCertificates = YES;
    _AfManager.securityPolicy = policy;
}

- (NSString*)dbPath;
{
    NSArray *Paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *DocumentDir = [Paths objectAtIndex:0];
    
    return [DocumentDir stringByAppendingPathComponent:@"comress.sqlite"];
}

- (void)copyDbToDocumentsDir
{
    BOOL isExist;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    isExist = [fileManager fileExistsAtPath:[self dbPath]];
    NSString *FileDB = [[[NSBundle mainBundle]resourcePath]stringByAppendingPathComponent:@"comress.sqlite"];
    if (isExist)
    {
        return;
    }
    else
    {
        NSError *error;
        
        [fileManager copyItemAtPath:FileDB toPath:[self dbPath] error:&error];
        
        if(error)
        {
            DDLogVerbose(@"settings copy error %@ [%@-%@]",error,THIS_FILE,THIS_METHOD);
            return;
        }
    }
}

#pragma - mark database migration

-(void)migrateDatabase
{
    __block NSNumber *dbVersionFlag = [NSNumber numberWithInt:0];
    
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *rsDbVersion = [db executeQuery:@"select version from db_version"];
        
        while ([rsDbVersion next]) {
            dbVersionFlag = [NSNumber numberWithInt:[rsDbVersion intForColumn:@"version"]];
        }
        
    }];
    
    if([dbVersionFlag intValue] == newDatabaseVersion)
        return;//latest db version, don't do any migration
    else
        [self dropTables];
    

    //create the tables
    NSArray *tablesToCreate = @[@"CREATE TABLE blocks (id INTEGER PRIMARY KEY AUTOINCREMENT, block_id INTEGER, block_no VARCHAR (30), is_own_block BOOLEAN, postal_code VARCHAR (25), street_name VARCHAR (30), latitude DOUBLE, longitude DOUBLE, cos_lat DOUBLE, cos_lng DOUBLE, sin_lat DOUBLE, sin_lng DOUBLE)",
                                @"CREATE TABLE blocks_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE blocks_user (id INTEGER PRIMARY KEY AUTOINCREMENT, block_id INTEGER)",
                                @"CREATE TABLE blocks_user_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE client (activation_code STRING, server_url STRING, api_url STRING, user_guid VARCHAR (255), initialise INT DEFAULT (0))",
                                @"CREATE TABLE comment (client_comment_id INTEGER PRIMARY KEY AUTOINCREMENT, comment_id INTEGER, client_post_id INTEGER, post_id INTEGER, comment TEXT, comment_on DATE, comment_by TEXT, comment_type TEXT)",
                                @"CREATE TABLE comment_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE comment_noti (post_id INTEGER, comment_id INTEGER, status TEXT, user_id VARCHAR (30), id INTEGER PRIMARY KEY AUTOINCREMENT, uploaded BOOLEAN DEFAULT (0))",
                                @"CREATE TABLE comment_noti_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE contract_type (id INTEGER, contract VARCHAR (30))",
                                @"CREATE TABLE db_version (version INTEGER)",
                                @"CREATE TABLE device_token (device_token VARCHAR (128))",
                                @"CREATE TABLE post (client_post_id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, post_id INTEGER, post_topic VARCHAR (255), post_by VARCHAR (30), post_date DATE, post_type VARCHAR (30), severity INT (0) DEFAULT (2), status INT (0) DEFAULT (0), address VARCHAR (30), level VARCHAR (30), block_id VARCHAR (25), postal_code VARCHAR (30), isUpdated INT DEFAULT (1), statusWasUpdated BOOLEAN DEFAULT (0), seen BOOLEAN DEFAULT (0), updated_on DATE, contract_type INTEGER DEFAULT (0))",
                                @"CREATE TABLE post_image (client_post_image_id INTEGER PRIMARY KEY AUTOINCREMENT, post_image_id INTEGER, client_post_id INTEGER, post_id INTEGER, client_comment_id INTEGER, comment_id INTEGER, image_path TEXT, status VARCHAR (30), downloaded VARCHAR (30), uploaded VARCHAR (30), image_type INT DEFAULT (1))",
                                @"CREATE TABLE post_image_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE post_last_request_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_checkarea (w_chkareaid INTEGER, w_chkarea VARCHAR (30), 'key' INTEGER DEFAULT (0))",
                                @"CREATE TABLE ro_checkarea_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_checklist (w_chklistid INTEGER DEFAULT (0), w_item VARCHAR (30), w_jobtypeid INTEGER DEFAULT (0), w_chkareaid INTEGER DEFAULT (0), id INTEGER PRIMARY KEY AUTOINCREMENT)",
                                @"CREATE TABLE ro_checklist_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_inspectionresult (w_scheduleid INTEGER, w_checklistid INTEGER, w_chkareaid INTEGER, w_reportby VARCHAR (30), w_checked INTEGER (30) DEFAULT (0), w_spochecked INTEGER (30) DEFAULT (0), w_status INTEGER DEFAULT (0), w_required_sync INTEGER DEFAULT (1), w_created_on DATE, chkAIid INTEGER DEFAULT (0))",
                                @"CREATE TABLE ro_job (w_jobid INTEGER, w_blkid INTEGER, w_barcode VARCHAR (30))",
                                @"CREATE TABLE ro_job_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_scanblock (w_client_scaninspid INTEGER PRIMARY KEY AUTOINCREMENT, w_scanblockid INTEGER, w_blkid INTEGER, w_companyid VARCHAR (30), w_scheduledate DATE, w_startscantime DATE, w_endscantime DATE)",
                                @"CREATE TABLE ro_scanchecklist (w_scanchklistid INTEGER, w_itemshortname VARCHAR (30), w_itemfullname VARCHAR (30))",
                                @"CREATE TABLE ro_scanchecklist_blk (w_scanchklistblkid INTEGER, w_scanchklistid INTEGER, w_blkid INTEGER, w_barcode VARCHAR (30))",
                                @"CREATE TABLE ro_scanchecklist_blk_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_scanchecklist_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_scaninspection (w_client_scaninspid INTEGER PRIMARY KEY AUTOINCREMENT, w_scaninspid INTEGER, w_client_scanblockid INTEGER, w_scanblockid INTEGER, w_scanchklistblkid INTEGER, w_jobid INTEGER, w_scanby VARCHAR (30), w_scandatetime DATE)",
                                @"CREATE TABLE ro_schedule (w_scheduleid INTEGER, w_blkid INTEGER, w_area VARCHAR (30), w_jobid INTEGER, w_jobtype VARCHAR (30), w_jobtypeId INTEGER, w_scheduledate DATE, w_actstarttime DATE, w_actendtime DATE, w_supchk DATE, w_actualdate DATE, w_supflag INTEGER DEFAULT (0), w_flag INTEGER DEFAULT (0), w_spochk DATE DEFAULT (0), w_required_sync INTEGER DEFAULT (0))",
                                @"CREATE TABLE ro_schedule_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE ro_sup_activeBlocks (id INTEGER PRIMARY KEY AUTOINCREMENT, activeDate DATE, block_id INTEGER DEFAULT (0), user_id VARCHAR (40))",
                                @"CREATE TABLE ro_user_blk (w_blkid INTEGER)",
                                @"CREATE TABLE ro_user_blk_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE su_address (client_address_id INTEGER PRIMARY KEY AUTOINCREMENT, address_id INTEGER DEFAULT (0), address VARCHAR (30), unit_no VARCHAR (30), specify_area VARCHAR (30), postal_code VARCHAR (30), block_id INTEGER DEFAULT (0))",
                                @"CREATE TABLE su_answers (client_answer_id INTEGER PRIMARY KEY AUTOINCREMENT, answer_id INTEGER DEFAULT (0), question_id INTEGER DEFAULT (0), rating INTEGER DEFAULT (0), client_survey_id INTEGER DEFAULT (0), survey_id DEFAULT (0))",
                                @"CREATE TABLE su_feedback (client_feedback_id INTEGER PRIMARY KEY AUTOINCREMENT, feedback_id INTEGER DEFAULT (0), client_survey_id INTEGER DEFAULT (0), survey_id DEFAULT (0), description VARCHAR (30), address_id INTEGER DEFAULT (0), client_address_id INTEGER DEFAULT (0))",
                                @"CREATE TABLE su_feedback_issue (client_feedback_issue_id INTEGER PRIMARY KEY AUTOINCREMENT, feedback_issue_id INTEGER DEFAULT (0), client_feedback_id INTEGER DEFAULT (0), feedback_id INTEGER DEFAULT (0), client_post_id INTEGER DEFAULT (0), post_id INTEGER DEFAULT (0), issue_des VARCHAR (30), auto_assignme BOOLEAN DEFAULT (1), status INTEGER DEFAULT (0))",
                                @"CREATE TABLE su_feedback_issues_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE su_questions (id INTEGER PRIMARY KEY AUTOINCREMENT, en VARCHAR (200), cn VARCHAR (200), my VARCHAR (200), ind VARCHAR (200), question_id INTEGER DEFAULT (0))",
                                @"CREATE TABLE su_questions_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE su_survey (client_survey_id INTEGER PRIMARY KEY AUTOINCREMENT, survey_id INTEGER DEFAULT (0), client_survey_address_id INTEGER DEFAULT (0), survey_address_id INTEGER DEFAULT (0), survey_date DATE DEFAULT (0), resident_name VARCHAR (100), resident_age_range VARCHAR (30), resident_gender VARCHAR (5), resident_race VARCHAR (30), client_resident_address_id INTEGER DEFAULT (0), resident_address_id INTEGER DEFAULT (0), average_rating INTEGER DEFAULT (0), resident_contact VARCHAR (30), status INTEGER DEFAULT (0), resident_email VARCHAR (30), data_protection INTEGER DEFAULT (0), other_contact VARCHAR (30), isMine BOOLEAN DEFAULT (1), created_by VARCHAR (50))",
                                @"CREATE TABLE su_survey_last_req_date (id INTEGER PRIMARY KEY AUTOINCREMENT, date DATE)",
                                @"CREATE TABLE users (client_id INTEGER PRIMARY KEY AUTOINCREMENT, user_name VARCHAR (30), full_name STRING, guid STRING, email VARCHAR (30), device_token VARCHAR (128), company_id VARCHAR (30), user_id INT, company_name VARCHAR (30), group_id INT, group_name VARCHAR (25), device_id INTEGER, is_active INT DEFAULT (0), contract_type INTEGER)",
];
    
    
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        db.traceExecution = YES;
        
        for (int i = 0; i < tablesToCreate.count; i++) {
            BOOL create = [db executeUpdate:[tablesToCreate objectAtIndex:i]];
            
            if(!create)
            {
                *rollback = YES;
                return ;
            }
        }
    }];
    
    
    
    //insert defaults
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL insContractType1 = [db executeUpdate:@"insert into contract_type(id, contract) values (?,?)",[NSNumber numberWithInt:1],@"Conservancy"];
        if(!insContractType1)
        {
            *rollback = YES;
            return;
        }
        
        BOOL insContractType2 = [db executeUpdate:@"insert into contract_type(id, contract) values (?,?)",[NSNumber numberWithInt:2],@"Horticulture"];
        if(!insContractType2)
        {
            *rollback = YES;
            return;
        }
        
        BOOL insContractType3 = [db executeUpdate:@"insert into contract_type(id, contract) values (?,?)",[NSNumber numberWithInt:4],@"Pump"];
        if(!insContractType3)
        {
            *rollback = YES;
            return;
        }
        
        BOOL insContractType4 = [db executeUpdate:@"insert into contract_type(id, contract) values (?,?)",[NSNumber numberWithInt:5],@"Mosquito"];
        if(!insContractType4)
        {
            *rollback = YES;
            return;
        }
        
        FMResultSet *rsCheckDbVersion = [db executeQuery:@"select version from db_version"];
        if([rsCheckDbVersion next] == NO)
        {
            BOOL insDbVersion = [db executeUpdate:@"insert into db_version(version) values (?)",[NSNumber numberWithInt:newDatabaseVersion]];
            if(!insDbVersion)
            {
                *rollback = YES;
                return;
            }
        }
        else
        {
            BOOL insDbVersion = [db executeUpdate:@"update db_version set version = ?",[NSNumber numberWithInt:newDatabaseVersion]];
            if(!insDbVersion)
            {
                *rollback = YES;
                return;
            }
        }
    }];
}


- (void)dropTables
{
    NSMutableArray *tableDropScript = [[NSMutableArray alloc] init];
    
    //get all tables to drop
    [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {
        
        FMResultSet *rsGetAllTablesToDelete = [db executeQuery:@"select 'drop table ' || name || ';' from sqlite_master where type = 'table'"];
        
        while ([rsGetAllTablesToDelete next]) {
            [tableDropScript addObject:[rsGetAllTablesToDelete resultDictionary]];
        }
    }];
    
    
    //execute the drop table script
    for (int i = 0; i < tableDropScript.count; i++) {
        [_databaseQ inTransaction:^(FMDatabase *db, BOOL *rollback) {

            db.traceExecution = YES;
            
            NSString *dropScript = [[[tableDropScript objectAtIndex:i] allValues] firstObject];
            
            BOOL drop = [db executeUpdate:dropScript];
            
            if(!drop)
            {
                *rollback = YES;
                return;
            }
        }];
    }
}

- (void)alertMessageWithMessage:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Comress" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (NSDate *)createNSDateWithWcfDateString:(NSString *)dateString
{
    //the wcf is gmt+8 by default :-(
    //NSInteger offset = [[NSTimeZone defaultTimeZone] secondsFromGMT];
    
    NSInteger startPosition = [dateString rangeOfString:@"("].location + 1;
    NSTimeInterval unixTime = [[dateString substringWithRange:NSMakeRange(startPosition, 13)] doubleValue] / 1000;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    
    return date;
}

- (void)notifyLocallyWithMessage:(NSString *)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadIssuesList" object:nil];
    
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = message;
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (NSString *)toJsonString:(id)obj
{
    NSError *error;
    NSString *jsonString;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:obj
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
       jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return jsonString;
}


@end
