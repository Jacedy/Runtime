//
//  Teacher.m
//  test2
//
//  Created by 贾则栋 on 17/2/9.
//  Copyright © 2017年 贾则栋. All rights reserved.
//

#import "Teacher.h"
#import <objc/runtime.h>
#import "WZLSerializeKit.h"

//是否使用通用的encode/decode代码一次性encode/decode
#define USING_ENCODE_KIT    1

@implementation Teacher

WZLSERIALIZE_CODER_DECODER();

WZLSERIALIZE_COPY_WITH_ZONE();

WZLSERIALIZE_DESCRIPTION();

@end
