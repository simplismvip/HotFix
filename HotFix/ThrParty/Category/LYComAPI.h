//
//  LYComAPI.h
//  LYFix
//
//  Created by xly on 2018/9/17.
//  Copyright © 2018年 Xly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LYComAPI : NSObject

+ (NSString *)classNameWithInstance:(NSObject *)instance;
+ (UIViewController *)currentViewController;

@end
