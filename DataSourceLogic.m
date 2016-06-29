//
//  DataSourceLogic.m
//  Naton
//
//  Created by nato on 16/6/2.
//  Copyright © 2016年 naton. All rights reserved.
//

#import "DataSourceLogic.h"
#import "DataBase.h"
#import "NTHttpRequest.h"
#import "AESCrypt.h"
static NSString * const KEY_STRING = @"U1MjU1M0FDOUZ.Qz";
typedef void(^httpRequestBlock)(NSArray * returnArray);
typedef void(^errorBlk)(NSString * errorString);
/**
 *  request最后请求的时间间隔 15秒
 */
const int LastRequestTime = 15;
/**
 *  当天请求成功的时间间隔 30分钟      30 * 60
 */
const int LastModifyTime = 30 * 60;

@implementation DataSourceLogic
{
    /**
     *  存放内存中的字典
     */
    NSDictionary * _memoryDictonary;
    /**
     *  用户的userid
     */
    NSString * _userId;
    /**
     *  时间
     */
    NSString * _date;
    /**
     *  时间戳
     */
    NSInteger _timesTamp;
    /**
     *  用户session
     */
    NSString * _session;
    
}

- (instancetype)initWithMemoryDic:(NSDictionary *)memoryDictonary andWithUserId:(NSString *)userId andWithDate:(NSString *)date andWithTimestam:(NSInteger)timesTamp andWithSession:(NSString *)session{
    
    if (self = [super init]) {
        _memoryDictonary = memoryDictonary;
        _userId = userId;
        _date = date;
        _timesTamp = timesTamp;
        _session = session;
        
    }
    return self;
}

//返回数据的最终形式
- (void)returnTheResultDataSourcWithType:(BOOL)netWorkType ReturnBlock:(dataResultBlock)block {
    
 //内存和数据库的判断
    //判断memoryDictonary中是否存在此日期的时间
    BOOL isHave = [self memoryDictIsHaveAndWithDate:_date];
    
    //根据memory中是否存在进行相应的分支
   NSDictionary * resultDictionary = [self getResorceDataFromDBWithIsHaveInMemory:isHave andWihMemoryDickies:_memoryDictonary andWithDate:_date andWithUserId:_userId];
    block(resultDictionary);
    
    
    
 //网络请求
    
    //判断最后一次刷新时间和当前时间进行相应的判断(如果当前时间和最后一次请求时间间隔大于15秒请求网络,小于15秒分钟不进行网络请求 并且当天请求成功时间和数据库中lasymodify进行比较 时间间隔大于30分钟请求网络 小于30分钟不请求网络)
    BOOL shoulRequst = [self compareNowTimeAndWithLastRequestTimeWithActDate:_date];
//    if (_timesTamp == -1) {
//        shoulRequst = YES;
//    }
    
    
    if (!netWorkType) {
        //下拉刷新
        shoulRequst = YES;
    }
    
    //请求网络数据
    if (shoulRequst) {
        //获得数据库链接
        DataBase * dbqueue = [DataBase shareDataBase];
        //查询出lastmodify中的时间间隔
        BOOL coldOrHot = [self judgeTheNetWorkWndWithDate:_date];
        NSInteger lastUpdateTime;
//        if (_timesTamp == -1) {
//            lastUpdateTime = 0;
//        }else{
        lastUpdateTime = [dbqueue selectLastModifyTimeWithActDate:_date andWithHotOrCold:coldOrHot andWithUserId:_userId];
//    }
        [self httpRequestCalendarActWithActDate:_date andwithUserId:_userId andWithSession:_session andWithLastmodify:lastUpdateTime];
        
    }else{
        //不请求网络数据
        if ([self.delegate respondsToSelector:@selector(netWorkNotRequest)]) {
            [self.delegate netWorkNotRequest];
        }
        
    }
}
/**
 *  判断memoryDictonary中是否存在此日期的时间
 */
- (BOOL)memoryDictIsHaveAndWithDate:(NSString *)date{
    BOOL isHAve;
    
    
    return isHAve;
}
/**
 *  根据memory中是否存在进行相应的分支
 *
 *  @param isHave memory中是否存在的bool
 */
- (NSDictionary *)getResorceDataFromDBWithIsHaveInMemory:(BOOL)isHave andWihMemoryDickies:(NSDictionary *)memoryDictonary andWithDate:(NSString *)date andWithUserId:(NSString *)userId{
    
    if (isHave) {
        //存在
        return [memoryDictonary objectForKey:date];
    }else{
        //不存在
            //从数据库中读取数据
       NSDictionary * resultDict = [self getCalendarsDataSoucreFormDBWithDate:date andWithUserId:userId];
        
        return resultDict;
    }
    
}
/**
 *  从数据库中获取数据
 *  @param date   时间
 *  @param usedId userid
 */
- (NSDictionary *)getCalendarsDataSoucreFormDBWithDate:(NSString *)date andWithUserId:(NSString *)userId{
    
    //获得数据库链接
    DataBase * dbqueue = [DataBase shareDataBase];
    //获得此userid的下属的工作行程(不追究我是否有下属都去查询我的下属的数据有就添加没有就不添加)
    
    //存放下属和本人userid的数组
    __block NSMutableArray * followerAndSelferIdArray = [NSMutableArray arrayWithCapacity:0];
    //存放下属和本人的username的数组
    __block NSMutableArray * followerAndSelferNameArray = [NSMutableArray arrayWithCapacity:0];
    //存放下属和本人的所有行程的字典
   __block NSMutableDictionary * userCalendarsDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
    //存放标志的数组
    __block NSMutableArray * followerAndSelferNameTypeArray = [NSMutableArray arrayWithCapacity:0];
    
    //获得下属和本人的id
    
        //本人的
    [followerAndSelferIdArray addObject:userId];
        //占位 本人的名称 没有实际作用
    [followerAndSelferNameArray addObject:userId];
        //占位
    [followerAndSelferNameTypeArray addObject:[NSString stringWithFormat:@"%@_%@",userId,userId]];
        //下属的
    [dbqueue getUserFollowerFromDataBaseWithUserId:userId andWithBlock:^(NSArray *follerDataArray) {
            for (NTUserLevel * userLevel in follerDataArray) {
                [followerAndSelferIdArray addObject:userLevel.userId2];
                [followerAndSelferNameArray addObject:userLevel];
                [followerAndSelferNameTypeArray addObject:[NSString stringWithFormat:@"%@_%@",userLevel.userId2,userLevel.user2Name]];
            }
        
    }];
    
    
    //获得calendars--所有的行程
    [dbqueue getUserCalndarActFormDataBaseWithUserId:followerAndSelferIdArray andWithDate:date andWithBlock:^(NSArray *userCalendarArray) {
        
        for (int i = 0; i < followerAndSelferNameTypeArray.count;i++) {
            NSMutableArray * calendarArr = [NSMutableArray arrayWithCapacity:0];
            for (CalendarListModel * model in userCalendarArray) {
                if ([model.userId isEqualToString:followerAndSelferIdArray[i]]) {
                    [calendarArr addObject:model];
                }
            }
            [userCalendarsDictionary setObject:calendarArr forKey:followerAndSelferNameTypeArray[i]];
        }
        
            
    }];
    
    NSDictionary * returnDict = [@{@"USERNAME":followerAndSelferNameArray,@"USERNAMETYPE":followerAndSelferNameTypeArray,@"CALENDDICTIONARY":userCalendarsDictionary} copy];
    
    return returnDict;
}
/**
 *  判断最后一次刷新时间和当前时间进行相应的判断(如果当前时间和最后一次请求时间间隔大于15秒请求网络,小于15秒分钟不进行网络请求 并且当天请求成功时间和数据库中lasymodify进行比较 时间间隔大于30分钟请求网络 小于30分钟不请求网络)
 *
 *  @param actDate 行程的时间
 */
- (BOOL)compareNowTimeAndWithLastRequestTimeWithActDate:(NSString *)actDate{
    
    //YES 请求网络 NO  不请求网络
    BOOL shoulRequst;
    //提取数据库中最后一次刷新时间 需要参数行程时间 actDate
    //提取数据库中的 lastrequest 和 lastmodify (冷数据直接根据actDate进行提取,热数据根据数据库中的0/0来取)
    BOOL coldOrHot = [self judgeTheNetWorkWndWithDate:actDate];
    //判断是否进行网络加载
    shoulRequst = [self getTheLastRequestAndLastModifyTimeForDBWithActDate:actDate andWithColdOrHot:coldOrHot andWithUserId:_userId];
    return shoulRequst;
}
/**
 *  进行网络请求 判断接口
 *
 *  @param actDate    行程时间
 *  @param userId     userid
 *  @param session    session
 *  @param lastmodify 最后一次修改时间
 */
- (void)httpRequestCalendarActWithActDate:(NSString *)actDate andwithUserId:(NSString *)userId andWithSession:(NSString *)session andWithLastmodify:(NSInteger)lastmodify{
    
    //判断是进行热接口网络请求还是冷接口进行网络请求
        // YES  热数据   NO  冷数据
    BOOL isDataForHttp = [self judgeTheNetWorkWndWithDate:actDate];
    
    //进行数据加密 AES 加密
    
    userId  = [AESCrypt encrypt:userId password:KEY_STRING];
    session = [AESCrypt encrypt:session password:KEY_STRING];
    
    
    __weak typeof(self) WeekSelf = self;
    //进行相应的网络请求
    [self NTgetHttpRequestWithUserId:userId andWithActDate:actDate andWithUserSeccion:session andWithBoolForData:isDataForHttp andWithLastmodify:lastmodify andWithBlock:^(NSArray *returnArray) {
        //将数据在model中进行处理
         NSArray * returnArr = [CalendarListModel calendarListModelOptionWithDataDictonary:returnArray];
        
        //开辟线程 异步向数据库中插入数据
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            //获得数据库链接
            DataBase * dbqueue = [DataBase shareDataBase];
            [dbqueue insertDataForCalendarActWithDataArray:returnArr];
            if ([WeekSelf.delegate respondsToSelector:@selector(netWorkEndWith:)]) {
                [WeekSelf.delegate netWorkEndWith:WeekSelf];
            }
            [dbqueue insertLastModifyTimeWithActDate:actDate andWithHotOrCold:isDataForHttp andWithUserId:userId andWithLastModifyTime:_timesTamp];
        });

    } andWithErrorBlock:^(NSString *errorString) {
        NSLog(@"asdfa");
        @try {
            if ([WeekSelf.delegate respondsToSelector:@selector(netWorkNotRequest)]) {
                [WeekSelf.delegate netWorkNotRequest];
            }
        } @catch (NSException *exception) {
            NSLog(@"获得崩溃");
        } @finally {
            NSLog(@"结束");
        }
        
    }];
    
    
}
/**
 *  判断网络请求是热接口还是冷接口
 *
 *  @param dateString 传入的时间
 *
 *  @return 返回的   YES  热数据   NO  冷数据
 */
- (BOOL)judgeTheNetWorkWndWithDate:(NSString *)dateString{
    
    NSDateFormatter * dateFor = [[NSDateFormatter alloc]init];
    [dateFor setDateFormat:@"yyyy-MM-dd"];
    NSDate * date = [dateFor dateFromString:dateString];
    NSDate * newdate = [[NSDate date] initWithTimeInterval:-24 * 60 * 60 * 7 sinceDate:[NSDate date]];
    
    if ([date timeIntervalSinceDate:newdate]>= 0) {
        //热数据
        return YES;
    }else {
        //冷数据
        return NO;
    }
    
}
/**
 *  REST网络请求 新的网络数据请求
 *
 *  @param userId    请求的用户的userid
 *  @param session   用户请求的session
 *  @param isBoolForDataHttp 判断是否是热数据或者冷数据
 */
- (void)NTgetHttpRequestWithUserId:(NSString *)userId andWithActDate:(NSString *)actDate andWithUserSeccion:(NSString *)session andWithBoolForData:(BOOL)isBoolForDataHttp andWithLastmodify:(NSInteger)lastmodify andWithBlock:(httpRequestBlock)block andWithErrorBlock:(errorBlk)err{
    //获得数据库链接
    DataBase * dbqueue = [DataBase shareDataBase];
    NTHttpRequest * http = [NTHttpRequest new];
    if (isBoolForDataHttp) {
        //热数据
        //数据库中进行时间间隔的插入
        [dbqueue insertLastRequestTimeWithActDate:actDate andWithHotOrCold:YES andWithUserId:userId andWithLastRequestTime:[self getNowUnixTime]];
        //lastmodify 调试0
        [http getDictForCalendarListHotWithParameters:@{@"session":session,@"userId":userId,@"lastTime":[NSNumber numberWithInteger:lastmodify]}  completionWithDictionaryBllock:^(NSDictionary *dictionaryData) {
            if ([[dictionaryData objectForKey:@"result"] intValue] == 0) {
                _timesTamp = [[dictionaryData objectForKey:@"lastTime"] integerValue];
                block([dictionaryData objectForKey:@"calendarList"]);
            }
        } withError:^(NSString *errorInfo) {
            err(errorInfo);
        }];
        
    }else {
        //冷数据
        //数据库中进行时间间隔的插入
        [dbqueue insertLastRequestTimeWithActDate:actDate andWithHotOrCold:NO andWithUserId:userId andWithLastRequestTime:[self getNowUnixTime]];
        
        NSMutableString * strDate = [NSMutableString stringWithString:actDate];
        for (int i = 0; i < strDate.length; i++) {
           unichar cha = [strDate characterAtIndex:i];
            if (cha == '-') {
                [strDate deleteCharactersInRange:NSMakeRange(i, 1)];
            }
        }
        [http getDictForCalendarListColdWithParameters:@{@"session":session,@"userId":userId,@"lastTime":[NSNumber numberWithInteger:lastmodify],@"dayTime":strDate} completionWithDictionaryBllock:^(NSDictionary *dictionaryData) {
            if ([[dictionaryData objectForKey:@"result"] intValue] == 0) {
                _timesTamp = [[dictionaryData objectForKey:@"lastTime"] integerValue];
                block([dictionaryData objectForKey:@"calendarList"]);
            }
        } withError:^(NSString *errorInfo) {
            err(errorInfo);
        }];
    }
    
    
}
/**
 *  提取数据库中的 lastrequest 和 lastmodify (冷数据直接根据actDate进行提取,热数据根据数据库中的0/0来取)
 *
 *  @param actDate   行程时间
 *  @param coldOrHot 是冷数据还是热数据 YES 热数据 NO 冷数据
 *
 *  @return 返回是否需要网络请求
 */
- (BOOL)getTheLastRequestAndLastModifyTimeForDBWithActDate:(NSString *)actDate andWithColdOrHot:(BOOL)coldOrHot andWithUserId:(NSString *)userId{
   __block BOOL shouldRequest;
    //获得数据库链接
    DataBase * dbqueue = [DataBase shareDataBase];
    //查询出lastmodify中的时间间隔
    [dbqueue selectLastModifyWithActDate:actDate andWithHotOrCold:coldOrHot andWithUserId:userId andWithBlock:^(NSDictionary *calendarActDictionary) {
//        lastNetRequestTime   lastUpdateTime
        NSInteger lastNetRequestTime = [[calendarActDictionary objectForKey:@"lastNetRequestTime"] integerValue];
        NSInteger lastUpdateTime = [[calendarActDictionary objectForKey:@"lastUpdateTime"] integerValue];
        
        //判断是否是在时间间隔内
        if ([self getNowUnixTime] - lastNetRequestTime > LastRequestTime && [self getNowUnixTime] - lastUpdateTime > LastModifyTime) {
            
            shouldRequest = YES;
        }else {
            shouldRequest = NO;
        }
    }];

    return shouldRequest;
}

//获得当前时间戳
- (NSTimeInterval)getNowUnixTime{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval time = [date timeIntervalSince1970];
    return time;
}

@end
