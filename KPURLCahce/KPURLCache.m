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
#pragma mark Has Object OR Not

- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat{

    KPCacheObject *obj = [[[KPCacheObject alloc] init] autorelease];
    obj.fileName = aName;
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
    
    KPCacheObject *obj = [[KPCacheObject alloc] initWithName:aName version:aVersion format:aFormat dataLength:[aData length]];
    
    //TODO: if exist    remove or not delete;
#warning ..
    BOOL isExist = [self hasDataForName:aName version:NSNotFound format:NSNotFound];
    if(isExist){
        KPCacheObject *tmpObj = [self getLocalObjWithName:aName];
        if(tmpObj.version == aVersion && tmpObj.format == aFormat){
            return YES;
        }else{
            //TODO: 因为是同名称的，所以觉得应该算是modify，，应该有对应的处理。
            [self removeFileName:aName fromDisk:YES];
        }
    }
    
    BOOL flag = [self storeToLocal:aData info:obj];
    
    if(flag){
        NSDictionary *objDic = [obj toDic];
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
    //update access Count;
    [self updateInfo:aName];
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
- (BOOL)renameFromName:(NSString *)anOldName toName:(NSString *)aNewName{
    BOOL flag = NO;
    return flag;
}

- (void)modifyDataVersion:(NSInteger)aVersion forName:(NSString *)aName{
    
}

#pragma mark -
#pragma mark Utility method

//for update
- (void)updateInfo:(NSString *)aName{
    KPCacheObject *obj = [self getLocalObjWithName:aName];
    NSDictionary *dicBeforeUpdate = [obj toDic];
    
    [obj updateObjectInfo];
    NSUInteger index = [_cacheResourceList indexOfObject:dicBeforeUpdate];
    
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
//    if(index == NSNotFound){
//        return nil;
//    }
    
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
