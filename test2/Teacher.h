//
//  Teacher.h
//  test2
//
//  Created by 贾则栋 on 17/2/9.
//  Copyright © 2017年 贾则栋. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Biology.h"

@interface Teacher : Biology<NSCopying, NSCoding>
{
    NSString *_father;
}

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;

@end
