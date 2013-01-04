//
//  NSData+NSDataAddtions.m
//  KPURLCahce
//
//  Created by Wang Neo on 13-1-4.
//  Copyright (c) 2013年 王浩宇. All rights reserved.
//

#import "NSData+NSDataAddtions.h"
#import <CommonCrypto/CommonDigest.h>
@implementation NSData (NSDataAddtions)


- (NSString *)md5Hash{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5([self bytes], [self length], result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
            ];
}
@end
