//
//  HFTool.h
//  HotFix
//
//  Created by JunMing on 2020/6/22.
//  Copyright © 2020 JunMing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFTool : NSObject
+ (NSString *)jsFile:(NSString *)jsName;
@end

@interface HFTestClass : NSObject
/// 这两个方法参数传空会崩溃
- (void)instanceMethodCrash:(NSString * _Nullable)string;
+ (void)calssMethodCrash:(NSString * _Nullable)string;

// 替换方法，调用这个方法实际上会调用 replaceLog:这个方法
- (void)instanceReplace:(NSString * _Nullable)string;

// 修改参数
- (void)changePrames:(NSString * _Nullable)string;

// 修改参数
- (void)runBefore:(NSString * _Nullable)string;
@end

NS_ASSUME_NONNULL_END
