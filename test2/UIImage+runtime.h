//
//  UIImage+runtime.h
//  test2
//
//  Created by 贾则栋 on 17/2/9.
//  Copyright © 2017年 贾则栋. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (runtime)

@property (nonatomic,copy) NSString *sexProperty;

// 声明方法
// 如果跟系统方法差不多功能,可以采取添加前缀,与系统方法区分
+ (UIImage *)jk_imageWithName:(NSString *)imageName;

@end
