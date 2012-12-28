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

typedef NS_ENUM(NSUInteger, EnumDateFormat) {
	eDateFormatPNG,			//png
	eDateFormatMP3,           //mp3
    eDateFormatOther          //未记录的格式
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


//store
- (void)storeData:(NSData *)aData fileName:(NSString *)aName;

- (void)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion;

- (void)storeData:(NSData *)aData fileName:(NSString *)aName format:(EnumDateFormat)aFormat;

- (void)storeData:(NSData *)aData fileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDateFormat )aFormat;

//read
- (id)dataForFileName:(NSString *)aName;

- (id)dataForFileName:(NSString *)aName version:(NSInteger)aVersion;

- (id)dataForFileName:(NSString *)aName format:(EnumDateFormat)aFormat;

- (id)dataForFileName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDateFormat)aFormat;

//find
- (BOOL)hasDataForName:(NSString *)aName;

- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion;

- (BOOL)hasDataForName:(NSString *)aName format:(EnumDateFormat)aFormat;

- (BOOL)hasDataForName:(NSString *)aName version:(NSInteger)aVersion format:(EnumDateFormat)aFormat;


//remove
- (void)removeAll:(BOOL)fromDisk;

- (BOOL)removeFileName:(NSString *)aName fromDisk:(BOOL)fromDisk;
// if needs we can add Others;

//modify
- (BOOL)moveDataFromName:(NSString *)anOldName toName:(NSString *)aNewName;

- (void)modifyDataVersion:(NSInteger)aVersion forName:(NSString *)aName;


@end
