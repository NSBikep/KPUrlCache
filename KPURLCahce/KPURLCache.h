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
    
    NSMutableArray      *_recordArray;          //the array record in plist ,there are KPCacheObjects in array
    
    float               _cache;
    
}


@property (nonatomic,assign)NSUInteger eachMaxCapacityInMemory;

@property (nonatomic,assign)NSUInteger cacheMaxCache;

//@property (nonatomic,copy)NSString *diskPath;

@property (nonatomic,assign)EnumKPURLCachePolicy cachePolicy;

+ (KPURLCache *)sharedCache;

+ (KPURLCache *)sharedCacheByName:(NSString *)aName;

+ (void)setSharedURLCache: (KPURLCache *)aCache;


//store
- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName;

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion;

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName format:(EnumDataFormat)aFormat;

- (BOOL)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat )aFormat;

//read
- (NSData *)dataForFileName:(NSString *)aName;

- (NSData *)dataForFileName:(NSString *)aName version:(NSInteger)aVersion;

- (NSData *)dataForFileName:(NSString *)aName format:(EnumDataFormat)aFormat;

- (NSData *)dataForFileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat;

//find
//- (BOOL)hasDataForName:(NSString *)aName;
//
//- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion;
//
//- (BOOL)hasDataForName:(NSString *)aName format:(EnumDataFormat)aFormat;
//
- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDataFormat)aFormat;


//remove
- (void)removeAll:(BOOL)fromDisk;

- (BOOL)removeFileName:(NSString *)aName fromDisk:(BOOL)fromDisk;
// if needs we can add Others;

//modify
- (BOOL)renameFromName:(NSString *)anOldName toName:(NSString *)aNewName;

//- (BOOL)moveDataFromName:(NSString *)anOldName toName:(NSString *)aNewName;

- (void)modifyDataVersion:(NSInteger)aVersion forName:(NSString *)aName;


@end
