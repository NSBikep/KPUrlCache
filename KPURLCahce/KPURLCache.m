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
            [_cacheMemoryResource setObject:aData forKey:storeName];
        }
        [self saveDataImmediately:YES];
    }
    [obj release];
    return flag;
}

#pragma mark -
#pragma mark read Data
- (NSData *)dataForFileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat{
    //check in Memory
    NSString *fileKey = [self keyForFileName:aName];
    NSData *data = nil;
    data = [_cacheMemoryResource valueForKey:fileKey];
    if(data == nil){
        BOOL flag = [self hasDataForName:aName version:aVersion format:aFormat];
        if(flag){
            NSString *filePath = [self cachePathForKey:fileKey];
            NSFileManager* fm = [NSFileManager defaultManager];
            if([fm fileExistsAtPath:filePath]){
                data = [NSData dataWithContentsOfFile:filePath];
            }
        }
    }
    return data;
}

- (NSData *)dataForFileName:(NSString *)aName{
    return [self dataForFileName:aName version:NSNotFound format:NSNotFound];
}

- (NSData *)dataForFileName:(NSString *)aName format:(EnumDataFormat)aFormat{
    return [self dataForFileName:aName version:NSNotFound format:aFormat];
}

- (NSData *)dataForFileName:(NSString *)aName version:(NSInteger)aVersion{
    return [self dataForFileName:aName version:aVersion format:NSNotFound];
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
            flag = [fm removeItemAtPath:[self cachePathForName:filePath] error:nil];
        }
        if (flag) {
            //I have rewrited KPCacheObject's "equal to" method
            // need better way
            KPCacheObject *obj = [[KPCacheObject alloc] init];
            obj.fileName = aName;
            NSUInteger index = [_recordArray indexOfObject:obj];
            [obj release];
            KPCacheObject *objFromArr = [_recordArray objectAtIndex:index];
            [_cacheResourceList removeObject:[objFromArr toDic]];
            [_recordArray removeObject:objFromArr];
            
            [self saveDataImmediately:YES];
        }
    }
    return flag;
}

#pragma mark -
#pragma mark modify

- (BOOL)renameFromName:(NSString *)anOldName toName:(NSString *)aNewName{
    BOOL flag = NO;
    KPCacheObject *obj = [[KPCacheObject alloc] init];
    obj.fileName = anOldName;
    if([_recordArray containsObject:obj]){
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *oldFilePath = [self cachePathForName:anOldName];
        if([fm fileExistsAtPath:oldFilePath]){
            NSString *newFilePath = [self cachePathForName:aNewName];
            //未完成
        }
    }
    return flag;
}

- (void)modifyDataVersion:(NSInteger)aVersion forName:(NSString *)aName{
    
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

@end
