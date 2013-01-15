//
//  KPCacheObject.h
//  KPURLCahce
//
//  Created by 王浩宇 on 12-12-25.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KPCacheConstant.h"




//typedef NS_ENUM(NSUInteger, EnumDataFormat) {
//	eDataFormatPNG,			//png
//	eDataFormatMP3,           //mp3
//    eDataFormatOther          //未记录的格式
//};

@interface KPCacheObject : NSObject{
    EnumDataFormat  _format;
}

//file Name
@property (nonatomic,copy)NSString      *fileName;
//version
@property (nonatomic,copy)NSString      *tag;
//Access Count
@property (nonatomic,assign)NSInteger  accessCount;
//Create Date
@property (nonatomic,retain)NSDate     *creatDate;
//Effective Period
@property (nonatomic,assign)CGFloat     effectivePeriod;   //TODO: 是否要做
//version ————for update.
@property (nonatomic,assign)NSInteger  resourceVersion;
//modify Date
@property (nonatomic,retain)NSDate     *modifyDate;        
//access Date
@property (nonatomic,retain)NSDate     *lastAccessDate;
//data Length
@property (nonatomic)NSUInteger    dataLength;
//net Address
@property (nonatomic,copy)NSString    *netAddress;          //TODO: 如何赋值

//location Address
@property (nonatomic,copy)NSString   *localAddress;         //TODO: 如何赋值

//DataFormate
@property (nonatomic,readonly)EnumDataFormat  format;



#warning 是否需要加入一个断点的变量，例如etag的东西

- (NSDictionary *)toDic;
- (id)initWithDic:(NSDictionary *)aDic;
- (id)initWithName:(NSString *)aName tag:(NSString *)aDataTag length:(NSUInteger)aDataLength;
- (void)updateObjectInfo;

@end
