//
//  WHYAppDelegate.m
//  KPURLCahce
//
//  Created by 王浩宇 on 12-12-25.
//  Copyright (c) 2012年 王浩宇. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    //NSString *QQnum;
    //[KPURLCache sharedCacheByName:QQnum];
    
    //test data
    UIImage *ima   = [UIImage imageNamed:@"aaaa.png"];
    NSData *data = UIImagePNGRepresentation(ima);
    //[KPURLCache sharedCache];
    [[KPURLCache sharedCacheByName:@"Neo"] storeData:data fileName:@"helloworld" version:10 format:eDataFormatPNG];
    
    [[KPURLCache sharedCacheByName:@"Neo"] storeData:data fileName:@"helloworld2" version:10 format:eDataFormatPNG];
    
    //[[KPURLCache sharedCacheByName:@"Neo"] removeFileName:@"helloworld2" fromDisk:YES];
    
    NSData *data2 = [[KPURLCache sharedCacheByName:@"Neo"] dataForFileName:@"helloworld2"];
    UIImage *image2= [UIImage imageWithData:data2];
    [self.window addSubview:[[UIImageView alloc] initWithImage:image2]];
    
    
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (int i = 0 ; i<4; i++) {
        NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"test"];
        [arr addObject:dic];
    }
    NSDictionary *dic1 = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:3] forKey:@"test"];
    NSDictionary *dic2 = [arr objectAtIndex:3];
    BOOL a = [dic1 isEqualToDictionary:dic2];
    BOOL b = [dic1 isEqual:dic2];
    NSLog(@"a = %d,b = %d",a,b);
    NSLog(@"count = %d",[arr count]);
    [arr removeObject:dic1];
    NSLog(@"!count = %d",[arr count]);
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
