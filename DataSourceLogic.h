//
//  DataSourceLogic.h
//  Naton
//
//  Created by nato on 16/6/2.
//  Copyright © 2016年 naton. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DataSourceLogic;

typedef void(^dataResultBlock)(NSDictionary * resultDataDictionary);

@protocol DataSourceLogicDelegate <NSObject>
/**
 *  网络操作逻辑结束
 */
- (void)netWorkEndWith:(DataSourceLogic *)logic;
/**
 *  时间未到 不请求网络
 */
- (void)netWorkNotRequest;

@end

@interface DataSourceLogic : NSObject

@property (nonatomic,weak)id<DataSourceLogicDelegate>delegate;
/**
 *  实现数据的返回接口
 *
 *  netWorkType:是否是界面网络请求 还是下拉刷新 YES :界面网络请求  NO:下拉刷新
 *  @return 返回最终的结果数组
 */
- (void)returnTheResultDataSourcWithType:(BOOL)netWorkType ReturnBlock:(dataResultBlock)block;
/**
 *  重写构造方法
 *
 *  @param memoryDictonary 内存中存的字典 字典中存放的是行程数据
 *  @param userId          userid
 *  @param date            date
 *  @param timesTamps      lastmodif时间戳
 *  @param session         用户session
 *
 */
- (instancetype)initWithMemoryDic:(NSDictionary *)memoryDictonary andWithUserId:(NSString *)userId andWithDate:(NSString *)date andWithTimestam:(NSInteger)timesTamp andWithSession:(NSString *)session;
/**
 *  根据memory中是否存在进行相应的分支
 *
 *  @param isHave memory中是否存在的bool
 */
- (NSDictionary *)getResorceDataFromDBWithIsHaveInMemory:(BOOL)isHave andWihMemoryDickies:(NSDictionary *)memoryDictonary andWithDate:(NSString *)date andWithUserId:(NSString *)userId;
@end
