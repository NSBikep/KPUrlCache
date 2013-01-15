//
//  KPURLCache.m
//  KPURLCahce
//
//  Created by Wang Neo on 12-12-26.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import "KPURLCache.h"
#import "KPCacheObject.h"
#import "NSData+NSDataAddtions.h"


static  NSString* kDefaultCacheName       = @"KPURLCache";
static  KPURLCache *kShareCache = nil;
static  NSMutableDictionary *shareCaches = nil;
//static  int modifyTimes = 0;

#define KPURLCACHE_STORE_TIMES                5


#define KPURLCACHE_DEFAULT_VERSION            0
#define KPURLCACHE_DEFAULT_FORMAT             eDataFormatOther

@interface KPURLCache(){
    int modifyTimes;
}
@end

@implementation KPURLCache

@synthesize cacheMaxCache = _cacheMaxCount,cachePolicy = _cachePolicy,eachMaxCapacityInMemory = _eachMaxCapacityInMemory;


- (void)dealloc{
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: UIApplicationDidReceiveMemoryWarningNotification
     object: nil];
    [_name release];
    [_recordArray release];
    [_cacheMemoryResource release];
    [_cacheResourceList release];
    [_plistPath release];
    [self saveDataImmediately:YES];
    //[_diskPath release];
    [super dealloc];
}
#pragma mark -
#pragma mark create Cache Object
+ (KPURLCache *)sharedCache{
    @synchronized(self){
        if (nil == kShareCache) {
            kShareCache = [[KPURLCache alloc] initWithName:kDefaultCacheName];
        }
        return kShareCache;
    }
}

+ (KPURLCache *)sharedCacheByName:(NSString *)aName{
    if(nil == shareCaches){
        shareCaches = [[NSMutableDictionary alloc] init];
    }
    KPURLCache *cache = [shareCaches valueForKey:aName];
    if(nil == cache){
        cache = [[KPURLCache alloc]initWithName:aName];
        [shareCaches setValue:cache forKey:aName];
    }
    
    
    return cache;
    
}

+ (void)setSharedURLCache:(KPURLCache *)aCache{
    if (kShareCache != aCache) {
        [kShareCache release];
        kShareCache = [aCache retain];
    }
}

- (id)initWithName:(NSString *)aName{
    self = [super init];
    if(self){
        _name = [aName copy];
        _diskPath = [KPURLCache cacheDiskPathWithName:_name];
        _plistPath = [[self cachePlistPathWithName:_name] copy];
        _recordArray = [[NSMutableArray alloc] init];
        _cacheMemoryResource = [[NSMutableDictionary alloc] init];
        _invalidPolicy = KPURLCacheInvalidNone;
        _cacheResourceList = [[NSMutableArray alloc]initWithContentsOfFile:_plistPath];
        
        for(NSDictionary *dic in _cacheResourceList){
            KPCacheObject *obj = [[KPCacheObject alloc]initWithDic:dic];
            [_recordArray addObject:obj];
        }
        
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector(didReceiveMemoryWarning:)
         name: UIApplicationDidReceiveMemoryWarningNotification
         object: nil];
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector(didReceiveResignActive:)
         name: UIApplicationWillResignActiveNotification
         object: nil];
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector(didReceiveTerminate:)
         name: UIApplicationWillTerminateNotification
         object: nil];
    }
    return self;
}


#pragma mark -
#pragma mark Has Object OR Not    finish

- (BOOL)hasDataForName:(NSString *)aName{
    KPCacheObject *obj = [[[KPCacheObject alloc] init] autorelease];
    obj.fileName = aName;
    if([_recordArray containsObject:obj]){
        return YES;
    }
    return NO;
}

- (BOOL)hasDataForName:(NSString *)aName tag:(NSString *)aDataTag{
    KPCacheObject *obj = [[[KPCacheObject alloc] init] autorelease];
    obj.fileName = aName;
    if([_recordArray containsObject:obj]){
        NSUInteger index = [_recordArray indexOfObject:obj];
        if(index == NSNotFound){
            return NO;
        }
        KPCacheObject *actualObj = [_recordArray objectAtIndex:index];
        if([actualObj.tag isEqualToString:aDataTag]){
            return YES;
        }
    }
    return NO;
}


#pragma mark -
#pragma mark Store Data Object

- (BOOL)storeWithData:(NSData *)aData fileName:(NSString *)aName{
    return [self storeWithData:aData fileName:aName tag:@""];
}

- (BOOL)storeWithData:(NSData *)aData fileName:(NSString *)aName tag:(NSString *)aDataTag{
    //KPCacheObject *obj = [[KPCacheObject alloc] initWithName:aName tag:aDataTag length:[aData length]];
    if(([aDataTag isEqualToString:@""] &&[self hasDataForName:aName]) ||
       (![aDataTag isEqualToString:@""]&&[self hasDataForName:aName tag:aDataTag])){
        return [self modifyWithData:aData fileName:aName tag:aDataTag];
    }
    
    KPCacheObject *newObj = [[KPCacheObject alloc] initWithName:aName tag:aDataTag length:[aData length]];
    
    BOOL flag =  [self storeToLocal:aData info:newObj];
    if(flag){
        [_recordArray addObject:newObj];
        [_cacheResourceList addObject:[newObj toDic]];
        if(_cachePolicy == KPURLCachePolicyMemory){
            [_cacheMemoryResource setValue:aData forKey:[self keyForFileName:aName]];
        }
        [self saveDataImmediately:YES];
    }
    
    [newObj release];

    
    return flag;
}

#pragma mark -
#pragma mark read Data

- (NSData *)dataForName:(NSString *)aName{
    //check in Memory
    NSString *fileKey = [self keyForFileName:aName];
    NSData *data = nil;
    data = [_cacheMemoryResource valueForKey:fileKey];
    if(data == nil){
        BOOL flag = [self hasDataForName:aName];
        if(flag){
            NSString *filePath = [self cachePathForKey:fileKey];
            NSFileManager* fm = [NSFileManager defaultManager];
            if([fm fileExistsAtPath:filePath]){
                
                data = [NSData dataWithContentsOfFile:filePath];
                [self updateInfo:aName];
            }
        }
    }
    
    return data;
}

- (NSData *)dataForName:(NSString *)aName tag:(NSString *)aDataTag{
    NSString *fileKey = [self keyForFileName:aName];
    NSData *data = nil;
    data = [_cacheMemoryResource valueForKey:fileKey];
    if(data == nil){
        BOOL flag = [self hasDataForName:aName tag:aDataTag];
        if(flag){
            NSString *filePath = [self cachePathForKey:fileKey];
            NSFileManager* fm = [NSFileManager defaultManager];
            if([fm fileExistsAtPath:filePath]){
                data = [NSData dataWithContentsOfFile:filePath];
            }
        }
    }
    [self updateInfo:aName];
    return data;
}


#pragma mark -
#pragma mark remove

- (BOOL)removeAll:(BOOL)fromDisk{
    BOOL flag = NO;
    [_cacheMemoryResource removeAllObjects];
    //remove the folder
    if(fromDisk){
        NSFileManager *fm = [NSFileManager defaultManager];
        if(![fm fileExistsAtPath:_diskPath]){
            flag = YES;
        }else{
            flag = [fm removeItemAtPath:_diskPath error:nil];
        }        
        if(flag){
            [_cacheResourceList removeAllObjects];
            [_recordArray removeAllObjects];
            //save or not?
        }
    }
    return flag;
}

- (BOOL)removeFileName:(NSString *)aName fromDisk:(BOOL)fromDisk{
    BOOL flag = NO;
    [_cacheMemoryResource removeObjectForKey:[self keyForFileName:aName]];
    if(fromDisk){
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *filePath = [self cachePathForName:aName];
        if(![fm fileExistsAtPath:filePath]){
            flag = YES;
        }else{
            flag = [fm removeItemAtPath:filePath error:nil];
        }
        if (flag) {
            //I have rewrited KPCacheObject's "equal to" method
            // need better way
            KPCacheObject *objFromArr = [self getLocalObjWithName:aName];
            NSLog(@"%@",[objFromArr toDic]);
            [_cacheResourceList removeObject:[objFromArr toDic]];
            [_recordArray removeObject:objFromArr];
            
            [self saveDataImmediately:YES];
        }
    }
    return flag;
}

#pragma mark -
#pragma mark modify
//TODO: neccessary to do
- (BOOL)modifyWithData:(NSData *)aData fileName:(NSString *)aName tag:(NSString *)aDataTag{
    //处理内存
    if(_cachePolicy == KPURLCachePolicyMemory){
        NSData *tmpData = [aData copy];
        [_cacheMemoryResource setValue:tmpData forKey:[self keyForFileName:aName]];
        [tmpData release];
    }
    
    //处理2个Arr中的文件
    KPCacheObject *obj = [self getLocalObjWithName:aName];
    [_cacheResourceList removeObject:[obj toDic]];
    obj.modifyDate = [NSDate date];
    obj.tag = aDataTag;
    [_cacheResourceList addObject:[obj toDic]];
    [self saveDataImmediately:NO];
    
    
    //处理本地文件
    NSData *localData = [self dataForName:aName tag:aDataTag];
    if(localData && [aData isEqualToData:localData]){
        return YES;
    }else{
        return [self storeToLocal:aData info:obj];
    }
}

#pragma mark -
#pragma mark Utility method

//for update
- (void)updateInfo:(NSString *)aName{
    KPCacheObject *obj = [self getLocalObjWithName:aName];
    NSDictionary *dicBeforeUpdate = [obj toDic];
    
    [obj updateObjectInfo];
    NSUInteger index = [_cacheResourceList indexOfObject:dicBeforeUpdate];
    if(index == NSNotFound){
        return;
    }
    NSDictionary *dicAfterUpdate = [obj toDic];
    
    [_cacheResourceList replaceObjectAtIndex:index withObject:dicAfterUpdate];
    
    [self saveDataImmediately:NO];
}

//for modify
- (void)modifyIno:(NSString *)aName{
    
}

- (KPCacheObject *)getLocalObjWithName:(NSString *)aName{
    KPCacheObject *obj = [[KPCacheObject alloc] init];
    obj.fileName = aName;
    NSUInteger index = [_recordArray indexOfObject:obj];
    [obj release];
    if(index == NSNotFound){
        return nil;
    }
    
    KPCacheObject *objFromArr = [_recordArray objectAtIndex:index];
    return objFromArr;
}

- (BOOL)storeToLocal:(NSData *)aData info:(KPCacheObject *)anObject{
    
    //有想法以后放在plist中，以NSData的格式存储。
    NSString *fileName = anObject.fileName;
    anObject.dataLength = aData.length;
    NSString *storeName = [self keyForFileName:fileName];
    NSString* filePath = [self cachePathForKey:storeName];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL flag =[fm createFileAtPath:filePath contents:aData attributes:nil];
    return flag;
}

- (NSString*)cachePathForKey:(NSString*)aKey {
    return [_diskPath stringByAppendingPathComponent:aKey];
}

- (NSString*)cachePathForName:(NSString *)aName {
    NSString *fileKey = [self keyForFileName:aName];
    return [self cachePathForKey:fileKey];
}

- (NSString *)keyForFileName:(NSString *)aName{
    NSData *tmpData = [aName dataUsingEncoding:NSUTF8StringEncoding];
    return [tmpData md5Hash];
}

- (NSString *)cachePlistPathWithName:(NSString *)aName{
    if(!_diskPath){
        _diskPath = [KPURLCache cacheDiskPathWithName:aName];
    }
    NSString *plistPath = [_diskPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",aName]];
    
    [KPURLCache createFileIfNecessary:plistPath];
    
    return plistPath;
}

+ (NSString *)cacheDiskPathWithName:(NSString *)aName{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* cachesPath = [paths objectAtIndex:0];
    NSString* cachePath = [cachesPath stringByAppendingPathComponent:aName];
    
    [KPURLCache createPathIfNecessary:cachesPath];
    [KPURLCache createPathIfNecessary:cachePath];
    
    return cachePath;
}

+ (BOOL)createPathIfNecessary:(NSString *)aPath{
    BOOL succeeded = YES;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:aPath]) {
        succeeded = [fm createDirectoryAtPath: aPath
                  withIntermediateDirectories: YES
                                   attributes: nil
                                        error: nil];
    }
    
    return succeeded;
}

+ (BOOL)createFileIfNecessary:(NSString *)aPath{
    BOOL succeeded = YES;
    
    NSFileManager* fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:aPath]) {
        NSArray *tmpArray = [NSArray array];
        succeeded = [tmpArray writeToFile:aPath atomically:YES];
    }
    
    return succeeded;
}


#pragma mark -
#pragma mark save plist to local

- (void)saveDataImmediately:(BOOL)aFlag{
    //待考虑。。
    if(aFlag){
        //did right now
        [_cacheResourceList writeToFile:_plistPath atomically:YES];
        modifyTimes = 0;
    }else{
        //对次数进行判断
        if(modifyTimes == KPURLCACHE_STORE_TIMES){
            [self saveDataImmediately:YES];
        }else{
            modifyTimes++;
        }
    }
}


#pragma mark -
#pragma mark others
- (void)didReceiveMemoryWarning:(void*)object {
    // Empty the memory cache when memory is low
    [self removeAll:NO];
}

- (void)didReceiveResignActive:(NSNotification *)defaultNotifation{
    [self saveDataImmediately:YES];
}

- (void)didReceiveTerminate:(NSNotification *)defaultNotifation{
    [self saveDataImmediately:YES];
}

@end
