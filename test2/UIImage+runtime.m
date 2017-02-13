//
//  UIImage+runtime.m
//  test2
//
//  Created by 贾则栋 on 17/2/9.
//  Copyright © 2017年 贾则栋. All rights reserved.
//

#import "UIImage+runtime.h"
#import <objc/runtime.h>

@implementation UIImage (runtime)

static char *sexProperty = "sexProperty";

#pragma mark - 交换两个方法的实现
/*
定义完毕新方法后,需要弄清楚什么时候实现与系统的方法交互?
答 : 既然是给系统的方法添加额外的功能,换句话说,我们以后在开发中都是使用自己定义的方法,取代系统的方法,所以,当程序一启动,就要求能使用自己定义的功能方法.说道这里:我们必须要弄明白一下两个方法 :
+(void)initialize(当类第一次被调用的时候就会调用该方法,整个程序运行中只会调用一次)
+(void)load(当程序启动的时候就会调用该方法,换句话说,只要程序一启动就会调用load方法,整个程序运行中只会调用一次)
 
 不能在分类中重写系统方法imageNamed，因为会把系统的功能给覆盖掉，而且分类中不能调用super.
*/
+ (void)load {
    /*
     self:UIImage
     谁的事情,谁开头 1.发送消息(对象:objc) 2.注册方法(方法编号:sel) 3.交互方法(方法:method) 4.获取方法(类:class)
     Method:方法名
     
     获取方法,方法保存到类
     Class:获取哪个类方法
     SEL:获取哪个方法
     imageName
     */
    // 获取imageName:方法的地址
    Method imageNameMethod = class_getClassMethod(self, @selector(imageNamed:));
    
    // 获取wg_imageWithName:方法的地址
    Method wg_imageWithNameMethod = class_getClassMethod(self, @selector(jk_imageWithName:));
    
    // 交换方法地址，相当于交换实现方式
    method_exchangeImplementations(imageNameMethod, wg_imageWithNameMethod);
    
    
}

// 加载图片, 判断是否为空
+ (UIImage *)jk_imageWithName:(NSString *)imageName
{
    // 这里调用imageWithName，相当于调用imageName
    UIImage *image = [UIImage jk_imageWithName:imageName];
    if (!image) {
        NSLog(@"image not found!");
    }
    return image;
}

#pragma mark - 属性set/get方法
- (void)setSexProperty:(NSString *)sex
{
    objc_setAssociatedObject(self, &sexProperty, sex, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)sexProperty
{
    return objc_getAssociatedObject(self, &sexProperty);
}

@end
