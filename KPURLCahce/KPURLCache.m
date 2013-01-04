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
static  int modifyTimes = 0;

#define KPURLCACHE_STORE_TIMES                5


#define KPURLCACHE_DEFAULT_VERSION            0
#define KPURLCACHE_DEFAULT_FORMAT             eDataFormatOther

@implementation KPURLCache

@synthesize cacheMaxCache = _cacheMaxCount,cachePolicy = _cachePolicy,eachMaxCapacityInMemory = _eachMaxCapacityInMemory;
//@synthesize diskPath = _diskPath;


- (void)dealloc{
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: UIApplicationDidReceiveMemoryWarningNotification
     object: nil];
    [_name release];
    [_recordArray release];
    [_cacheMemoryResource release];
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
        _plistPath = [self cachePlistPathWithName:_name];
        _recordArray = [[NSMutableArray alloc] init];
        _cacheMemoryResource = [[NSMutableDictionary alloc] init];
        _cacheResourceList  = [[NSMutableArray alloc] init];
        NSArray *arr = [NSArray arrayWithContentsOfFile:_plistPath];
        for(NSDictionary *dic in arr){
            KPCacheObject *obj = [[KPCacheObject alloc]initWithDic:dic];
            [_recordArray addObject:obj];
        }
        
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector(didReceiveMemoryWarning:)
         name: UIApplicationDidReceiveMemoryWarningNotification
         object: nil];
    }
    return self;
}


#pragma mark -
#pragma mark Has Object OR Not

- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat{
    KPCacheObject *obj = [[KPCacheObject alloc]initWithName:aName version:aVersion format:aFormat];
    //looking for better idea.
    if([_recordArray containsObject:obj]){
        if(aVersion == NSNotFound && aFormat == NSNotFound){
            return YES;
        }else if(aVersion != NSNotFound){
            if(aVersion == obj.version){
                return YES;
            }
        }else if(aFormat != NSNotFound){
            if(aFormat == obj.format){
                return YES;
            }
        }else{
            if(aFormat == obj.format && aVersion == obj.version){
                return YES;
            }
        }
    }else{
        return NO;
    }
    return NO;
}


#pragma mark -
#pragma mark Store Data Object

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName{
    return [self storeData:aData fileName:aName version:KPURLCACHE_DEFAULT_VERSION format:KPURLCACHE_DEFAULT_FORMAT];
}

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName format:(EnumDataFormat)aFormat{
    return [self storeData:aData fileName:aName version:KPURLCACHE_DEFAULT_VERSION format:aFormat];
}

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion{
    return [self storeData:aData fileName:aName version:aVersion format:KPURLCACHE_DEFAULT_FORMAT];
}

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat{
    
    KPCacheObject *obj = [[KPCacheObject alloc] initWithName:aName version:aVersion format:aFormat];
    NSDictionary *objDic = [obj toDic];
    
    BOOL flag = [self storeToLocal:aData info:obj];
    
    if(flag){
        [_recordArray addObject:obj];
        [_cacheResourceList addObject:objDic];
        if(_cachePolicy == KPURLCachePolicyMemory){
            NSString *storeName = [self keyForFileName:aName];
            [_cacheMemoryResource setObject:objDic forKey:storeName];
        }
        [self saveDataImmediately:YES];
    }
    [obj release];
    return flag;
}

#pragma mark -
#pragma mark read Data
- (NSData *)dataForFileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat{
    BOOL flag = [self hasDataForName:aName version:aVersion format:aFormat];
    if(flag){
        
    }else{
        return nil;
    }
}


#pragma mark -
#pragma mark Utility method
- (BOOL)storeToLocal:(NSData *)aData info:(KPCacheObject *)anObject{
    
    //有想法以后放在plist中，以NSData的格式存储。
    NSString *fileName = anObject.fileName;
    NSString *storeName = [self keyForFileName:fileName];
    NSString* filePath = [self cachePathForKey:storeName];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL flag =[fm createFileAtPath:filePath contents:aData attributes:nil];
    return flag;
}

- (NSString*)cachePathForKey:(NSString*)aKey {
    return [_diskPath stringByAppendingPathComponent:aKey];
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
    //[self removeAll:NO];
}

@end
