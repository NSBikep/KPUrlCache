//
//  KPCacheObject.m
//  KPURLCahce
//
//  Created by 王浩宇 on 12-12-25.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import "KPCacheObject.h"




@implementation KPCacheObject

@synthesize accessCount,accessDate,creatDate,dataLength,effectivePeriod,formate,localAddress,modifyDate,netAddress,resourceVersion;
- (void)dealloc{
    [accessDate release];
    [creatDate release];
    [localAddress release];
    [modifyDate release];
    [netAddress release];
    [super dealloc];
}

- (id)initWithDic:(NSDictionary *)aDic{
    self = [super init];
    
}


@end
