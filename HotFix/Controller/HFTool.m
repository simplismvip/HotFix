//
//  HFTool.m
//  HotFix
//
//  Created by JunMing on 2020/6/22.
//  Copyright © 2020 JunMing. All rights reserved.
//

#import "HFTool.h"

@implementation HFTool
+ (NSString *)jsFile:(NSString *)jsName {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:jsName ofType:@"js"];
    NSString *jsString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
    return jsString;
}
@end

@implementation HFTestClass
// 修复闪退
+ (void)calssMethodCrash:(NSString * _Nullable)string {
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:string];
    NSLog(@"xly--%@",array);
}

- (void)instanceMethodCrash:(NSString * _Nullable)string {
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:string];
    NSLog(@"😭😭😭instanceMethodCrash--%@",array);
}

// 替换方法
- (void)instanceReplace:(NSString * _Nullable)string {
    NSLog(@"😭😭😭instanceReplace--%@",string);
}
- (NSString *)replaceLog:(NSString * _Nullable)string {
    NSLog(@"😃😃😃我是replaceLog，替换了：instanceReplace方法");
    return @"😃😃😃替换方法成功";
}

- (void)changePrames:(NSString * _Nullable)string {
    NSLog(@"%@:changePrames",string);
}

// js调用运行方法
- (void)runMethod:(NSString * _Nullable)string {
    NSLog(@"%@:runMethod",string);
}

// 调用这个方法之前回调用log的哦
- (void)runBefore:(NSString * _Nullable)string {
    NSLog(@"%@:runBefore",string);
}

- (void)log {
    NSLog(@"😃😃😃我是Log方法🥰🥰🥰");
}
@end
