//
//  KPURLCache.h
//  KPURLCahce
//
//  Created by Wang Neo on 12-12-26.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPCacheConstant.h"
typedef NS_ENUM(NSUInteger, EnumKPURLCachePolicy) {
	KPURLCachePolicyNone = 0,		//NO Cache     //not support
	KPURLCachePolicyMemory = (1<<0),		//Memory
    KPURLCachePolicyDisk = (1<<1),       //Disk
};



typedef NS_ENUM(NSUInteger, EnumKPURLInvalidPolicy){
    KPURLCacheInvalidNone,
    KPURLCacheInvalidInDate,
    KPURLCacheInvalidInCount
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
    
    NSMutableArray      *_recordArray;          //the array record in plist ,there are KPCacheObjects in array
    
    float               _cache;
    
    EnumKPURLInvalidPolicy   _invalidPolicy;
    
}


@property (nonatomic,assign)NSUInteger eachMaxCapacityInMemory;

@property (nonatomic,assign)NSUInteger cacheMaxCache;

//@property (nonatomic,copy)NSString *diskPath;

@property (nonatomic,assign)EnumKPURLCachePolicy cachePolicy;

+ (KPURLCache *)sharedCache;

+ (KPURLCache *)sharedCacheByName:(NSString *)aName;

+ (void)setSharedURLCache: (KPURLCache *)aCache;


//store
- (BOOL)storeWithData:(NSData *)aData fileName:(NSString *)aName;

- (BOOL)storeWithData:(NSData *)aData fileName:(NSString *)aName tag:(NSString *)aDataTag;

//read
- (NSData *)dataForName:(NSString *)aName;

- (NSData *)dataForName:(NSString *)aName tag:(NSString *)aDataTag;

//find
- (BOOL)hasDataForName:(NSString *)aName;

- (BOOL)hasDataForName:(NSString *)aName tag:(NSString *)aDataTag;

//remove
- (BOOL)removeAll:(BOOL)fromDisk;

- (BOOL)removeFileName:(NSString *)aName fromDisk:(BOOL)fromDisk;
// if needs we can add Others;

@end
