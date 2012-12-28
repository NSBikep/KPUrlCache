//
//  KPCacheObject.h
//  KPURLCahce
//
//  Created by 王浩宇 on 12-12-25.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>


#define KP_CACHE_OBJECT_




typedef NS_ENUM(NSUInteger, EnumDataFormat) {
	eDataFormatPNG,			//png
	eDataFormatMP3,           //mp3
    eDataFormatOther          //未记录的格式
};

@interface KPCacheObject : NSObject

//file Name
@property (nonatomic,copy)NSString      *fileName;

//Access Count
@property (nonatomic,assign)NSInteger  accessCount;
//Create Date
@property (nonatomic,retain)NSDate     *creatDate;
//Effective Period
@property (nonatomic,assign)CGFloat     effectivePeriod;
//version ————for update.
@property (nonatomic,assign)NSInteger  resourceVersion;
//modify Date
@property (nonatomic,retain)NSDate     *modifyDate;
//access Date
@property (nonatomic,retain)NSDate     *accessDate;
//data Length
@property (nonatomic,readonly)CGFloat    dataLength;
//net Address
@property (nonatomic,copy)NSString    *netAddress;

//location Address
@property (nonatomic,copy)NSString   *localAddress;

//DataFormate
@property (nonatomic,readonly)EnumDataFormat  formate;


- (NSDictionary *)toDic;
- (id)initWithDic:(NSDictionary *)aDic;
@end
