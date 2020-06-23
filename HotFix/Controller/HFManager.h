//
//  HFManager.h
//  HotFix
//
//  Created by JunMing on 2020/6/22.
//  Copyright © 2020 JunMing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface HFManager : NSObject
+ (void)FixRun;
+ (JSContext *)context;
+ (id)evalString:(NSString *)jsString;

+ (id)runWithClassname:(NSString *)className selector:(NSString *)selector arguments:(NSArray *)arguments;
+ (id)runWithInstance:(id)instance selector:(NSString *)selector arguments:(NSArray *)arguments;
@end

NS_ASSUME_NONNULL_END
