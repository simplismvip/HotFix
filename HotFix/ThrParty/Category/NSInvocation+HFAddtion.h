//
//  NSInvocation+HFAddtion.h
//  HotFix
//
//  Created by JunMing on 2020/6/22.
//  Copyright © 2020 JunMing. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSInvocation (HFAddtion)
@property (nonatomic, strong) id returnValue_obj;

@property (nonatomic, copy) NSArray *arguments;

- (void)setMyArgument:(id)obj atIndex:(NSInteger)argumentIndex;
- (id)myArgumentAtIndex:(NSUInteger)index;
@end

NS_ASSUME_NONNULL_END
