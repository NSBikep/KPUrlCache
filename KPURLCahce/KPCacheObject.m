//
//  KPCacheObject.m
//  KPURLCahce
//
//  Created by 王浩宇 on 12-12-25.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import "KPCacheObject.h"

#define KP_CACHEOBJECT_FORMAT       @"KPCacheObjectFormat"
#define KP_CACHEOBJECT_VERSION      @"KPCacheObjectVersion"
#define KP_CACHEOBJECT_NAME         @"KPCacheObjectName"
#define KP_CACHEOBJECT_ACCESSCOUNT  @"KPAccessCount"
#define KP_CACHEOBJECT_DATALENGTH   @"KPDataLength"
#define KP_CACHEOBJECT_CREATEDATE   @"KPDataCreateDate"
#define KP_CACHEOBJECT_LASTACCESSDATE   @"KPDataLastAccessDate"

@implementation KPCacheObject

@synthesize accessCount,lastAccessDate,creatDate,dataLength,effectivePeriod,format = _format,localAddress,modifyDate,netAddress,resourceVersion,fileName;
- (void)dealloc{
    [fileName release];
    [lastAccessDate release];
    [creatDate release];
    [localAddress release];
    [modifyDate release];
    [netAddress release];
    [super dealloc];
}


//dic to object    Now just for testing  , later I will add other infos; 
- (id)initWithDic:(NSDictionary *)aDic{
    self = [super init];
    if(self){
        self.fileName = [aDic valueForKey:KP_CACHEOBJECT_NAME];
        self.accessCount = [[aDic valueForKey:KP_CACHEOBJECT_ACCESSCOUNT] integerValue];
        self.version = [[aDic valueForKey:KP_CACHEOBJECT_VERSION] integerValue];
        self.accessCount = [[aDic valueForKey:KP_CACHEOBJECT_ACCESSCOUNT] integerValue];
        self.dataLength = [[aDic valueForKey:KP_CACHEOBJECT_DATALENGTH] integerValue];
        self.creatDate = [aDic valueForKey:KP_CACHEOBJECT_CREATEDATE];
        self.lastAccessDate = [aDic valueForKey:KP_CACHEOBJECT_LASTACCESSDATE];
    }
    return self;
    
}

- (id)initWithName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat dataLength:(NSUInteger)aDataLength{
    self = [super init];
    if(self){
        self.dataLength = aDataLength;
        self.fileName = aName;
        self.version = aVersion;
        _format = aFormat;
        self.lastAccessDate = [NSDate date];
        self.creatDate = [NSDate date];
        
    }
    return self;
}

- (NSDictionary *)toDic{
    NSMutableDictionary *resultDic = [NSMutableDictionary dictionary];
    [resultDic setObject:self.fileName forKey:KP_CACHEOBJECT_NAME];
    [resultDic setObject:[NSNumber numberWithInteger:self.version] forKey:KP_CACHEOBJECT_VERSION];
    [resultDic setObject:[NSNumber numberWithInteger:self.format] forKey:KP_CACHEOBJECT_FORMAT];
    [resultDic setObject:[NSNumber numberWithInteger:self.accessCount] forKey:KP_CACHEOBJECT_ACCESSCOUNT];
    [resultDic setObject:[NSNumber numberWithInteger:self.dataLength] forKey:KP_CACHEOBJECT_DATALENGTH];
    [resultDic setObject:self.creatDate forKey:KP_CACHEOBJECT_CREATEDATE];
    [resultDic setObject:self.lastAccessDate forKey:KP_CACHEOBJECT_LASTACCESSDATE];
    return resultDic;
}

- (BOOL)isEqual:(id)object{
    if (object != nil) {
        KPCacheObject* another = (KPCacheObject*)object;
        if ([another.fileName isEqualToString:self.fileName]) {
            return YES;
        }
    }
    return NO;
}

- (NSUInteger)hash{
    return [self.fileName hash];
}

- (void)updateObjectInfo{
    self.accessCount ++;
    self.lastAccessDate = [NSDate date];
}


@end
