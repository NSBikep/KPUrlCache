//
//  KPURLCache.m
//  KPURLCahce
//
//  Created by Wang Neo on 12-12-26.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import "KPURLCache.h"


static  NSString* kDefaultCacheName       = @"KPURLCache";
static  KPURLCache *kShareCache = nil;
static  NSMutableDictionary *shareCaches = nil;
static  int modifyTimes = 0;
@implementation KPURLCache

@synthesize cacheMaxCache = _cacheMaxCount,cachePolicy = _cachePolicy,eachMaxCapacityInMemory = _eachMaxCapacityInMemory;
//@synthesize diskPath = _diskPath;


- (void)dealloc{
    [[NSNotificationCenter defaultCenter]
     removeObserver: self
     name: UIApplicationDidReceiveMemoryWarningNotification
     object: nil];
    [_name release];
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
        
        [[NSNotificationCenter defaultCenter]
         addObserver: self
         selector: @selector(didReceiveMemoryWarning:)
         name: UIApplicationDidReceiveMemoryWarningNotification
         object: nil];
    }
    return self;
}

#pragma mark -
#pragma mark Utility method for Path
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



- (void)saveData{
    modifyTimes++;
    if(modifyTimes %5 == 0){
        //save....
    }else{
        modifyTimes = 0;
    }
}


#pragma mark -
#pragma mark others
- (void)didReceiveMemoryWarning:(void*)object {
    // Empty the memory cache when memory is low
    //[self removeAll:NO];
}

@end
