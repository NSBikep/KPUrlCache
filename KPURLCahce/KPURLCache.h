//
//  KPURLCache.h
//  KPURLCahce
//
//  Created by Wang Neo on 12-12-26.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, EnumKPURLCachePolicy) {
	KPURLCachePolicyNone = 1,		//NO Cache
	KPURLCachePolicyMemory = 2,		//Memory
    KPURLCachePolicyDisk = 4,       //Disk
};

@interface KPURLCache : NSObject{
    NSString            *_name;                  //name of cache
    NSString            *_plistPath;             //plist that records the disk Cache Info
    NSUInteger          _eachMaxCapacityInMemory;           //The maximum capacity of each element in the cache
    NSUInteger          _cacheMaxCount;              //the count of Objects in cache;
    NSString            *_diskPath;               //path is the location at which to store the on-disk cache.
    NSMutableArray      *_cacheResourceList;
    
    NSMutableDictionary *_cacheMemoryResource;
    
    EnumKPURLCachePolicy _cachePolicy;
    
    float               _cache;
    
}


@property (nonatomic,assign)NSUInteger eachMaxCapacityInMemory;

@property (nonatomic,assign)NSUInteger cacheMaxCache;

//@property (nonatomic,copy)NSString *diskPath;

@property (nonatomic,assign)EnumKPURLCachePolicy cachePolicy;

+ (KPURLCache *)sharedCache;

+ (KPURLCache *)sharedCacheByName:(NSString *)aName;

+ (void)setSharedURLCache: (KPURLCache *)aCache;



@end
