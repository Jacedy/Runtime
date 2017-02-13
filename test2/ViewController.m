//
//  ViewController.m
//  test2
//
//  Created by 贾则栋 on 17/2/9.
//  Copyright © 2017年 贾则栋. All rights reserved.
//
/* runtime 常见的使用有：
 1.动态创建一个类(比如KVO的底层实现)
 2.动态地为某个类添加属性\方法, 修改属性值\方法
 3.遍历一个类的所有成员变量(属性)\所有方法
 4.动态交换两个方法的实现
 5.实现分类也可以添加属性
 6.实现NSCoding的自动归档和解档
 7.实现字典转模型的自动转换
 8.Hook
 */

#import "ViewController.h"
#import <objc/runtime.h>
#import "Teacher.h"
#import "WZLSerializeKit.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#pragma mark - 创建类、添加实例变量、添加实例方法
    // 新建Person类
    Class Person = objc_allocateClassPair([NSObject class], "Person", 0);
    
    // 给Person类添加一个NSString类型的实例变量（instance variable），第四个参数是对其方式，第五个参数是参数类型
    class_addIvar(Person, "name", sizeof(NSString *), 0, "@");
    
    // 添加属性
    objc_property_attribute_t type = {"T", "@\"NSString\""};
    objc_property_attribute_t ownership = { "C", "" };
    objc_property_attribute_t backingivar = { "V", "_ivar1"};
    objc_property_attribute_t attrs[] = {type, ownership, backingivar};
    class_addProperty(Person, "property2", attrs, 3);
    
    // 给Person类添加一个实例方法（instance method）
    // "v@:@",解释v-返回值void类型,@-self指针id类型,:-SEL指针SEL类型
    class_addMethod(Person, @selector(getName), (IMP)getName, "v@:");
    // v@:@",解释v-返回值void类型,@-self指针id类型,:-SEL指针SEL类型,@-函数第一个参数为id类型
    class_addMethod(Person, @selector(setName:), (IMP)setName, "v@:@");
    
    // 注册Person类后才可使用
    objc_registerClassPair(Person);
    
    // 实例化一个Person类对象
    id person = [[Person alloc] init];
//    //可以看出class_createInstance和alloc的不同
//    id theObject = class_createInstance([NSString class], sizeof(unsigned));      // 在ARC下不允许使用
//    id str1 = [theObject init];
//    id str2 = [[NSString alloc] initWithString:@"test"];
    
    // 设置实例变量的值
    [person setValue:@"jacedy" forKey:@"name"];
//    object_setInstanceVariable(person, "name", (void *)&str);     // 在ARC下不允许使用
    
    // 调用getName方法
    NSLog(@"nameValue: %@", [person getName]);  // objc_msgSend(person, @selector(getName))
    
    // 重置name值
    [person setName:@"jabit"];
    NSLog(@"nameValue: %@", [person performSelector:@selector(getName)]);
    
    
#pragma mark - 遍历实例变量、属性、实例方法
    // 遍历所有实例变量
    unsigned int ivarCount = 0;
    Ivar *ivars = class_copyIvarList([Person class], &ivarCount);
    for (int i = 0; i < ivarCount; i++)
    {
        Ivar ivar = ivars[i];
        NSLog(@"变量名:%s", ivar_getName(ivar));
    }
    
    // 遍历所有属性(这里已为UIImage类添加了一个sexProperty属性）
    unsigned int propertyCount = 0;
    objc_property_t *propertys = class_copyPropertyList([UIImage class], &propertyCount);
    for (int i = 0; i < propertyCount; i++) {
        objc_property_t property = propertys[i];
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(property)];
        if ([propertyName isEqualToString:@"sexProperty"]) {
            NSLog(@"属性名 %s found", property_getName(property));
        }
    }
    
    // 遍历所有实例方法
    unsigned int methodCount = 0;
    Method *methods = class_copyMethodList([Person class], &methodCount);
    for (int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        NSLog(@"方法名:%@", NSStringFromSelector(selector));
    }
    

#pragma mark - 交换两个方法测试
    [UIImage imageNamed:@"123456789.png"];
    
    
#pragma mark - 编码与解码
    Teacher *teacher = [[Teacher alloc] init];
    teacher.name = @"jacedy";
    teacher.age = 18;
    [teacher setValue:@"jabit" forKey:@"_father"];
    //set value of superClass
    teacher.introInBiology = @"I am a biology on earth";
    //[teacher setValue:@(10000) forKey:@"_hairCountInBiology"];//no access to private instance in super
    
    NSLog(@"Before archiver:\n%@", [teacher description]);
    
    WZLSERIALIZE_ARCHIVE(teacher, @"Teacher", [self filePath]);
    Teacher *theTeacher = nil;
    WZLSERIALIZE_UNARCHIVE(theTeacher, @"Teacher", [self filePath]);
    
    Teacher *copyTeacher = [teacher copy];
    NSLog(@"copyTeacher:%@", [copyTeacher description]);
    
    
#pragma mark - Hook拦截
/*
 使用method swizzling需要注意的问题:
 1.Swizzling应该总在+load中执行：Objective-C在运行时会自动调用类的两个方法+load和+initialize。+load会在类初始加载时调用，和+initialize比较+load能保证在类的初始化过程中被加载
 2.Swizzling应该总是在dispatch_once中执行：swizzling会改变全局状态，所以在运行时采取一些预防措施，使用dispatch_once就能够确保代码不管有多少线程都只被执行一次。这将成为method swizzling的最佳实践。
 3.Selector，Method和Implementation：这几个之间关系可以这样理解，一个类维护一个运行时可接收的消息分发表，分发表中每个入口是一个Method，其中key是一个特定的名称，及SEL，与其对应的实现是IMP即指向底层C函数的指针。
 */
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        // When swizzling a class method, use the following:
        // Class class = object_getClass((id)self);
        
        //通过method swizzling修改了UIViewController的@selector(viewWillAppear:)的指针使其指向了自定义的jk_viewWillAppear
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(jk_viewWillAppear:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        
        //如果类中不存在要替换的方法，就先用class_addMethod和class_replaceMethod函数添加和替换两个方法实现。但如果已经有了要替换的方法，就调用method_exchangeImplementations函数交换两个方法的Implementation。
        if (didAddMethod) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
    
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");
}

- (void)jk_viewWillAppear:(BOOL)animated {
    NSLog(@"Hook : 拦截到viewwillApear的实现，在其基础上添加了这行代码");
    [self jk_viewWillAppear:YES];
}


#pragma mark - 变量name的get方法
// 这个方法实际上没有被调用,但是必须实现否则不会调用下面的方法
- (id)getName
{
    NSLog(@"getName called");
    
    // 获取实例变量
    Ivar nameIvar = class_getInstanceVariable([self class], "name");
    // 获取实例变量的值
    id name = object_getIvar(self, nameIvar);
    
    return name;
}

// 实际调用的是这个方法
static id getName(id self, SEL _cmd) //self和_cmd是必须的，在之后可以随意添加其他参数
{
    NSLog(@"static getName called");
    
    // 获取实例变量
    Ivar nameIvar = class_getInstanceVariable([self class], "name");
    // 获取实例变量的值
    id name = object_getIvar(self, nameIvar);
    
    return name;
}

#pragma mark - 变量name的set方法
- (void)setName:(id)name
{
    NSLog(@"setName called");
    
    // 获取实例变量
    Ivar nameIvar = class_getInstanceVariable([self class], "name");
    // 设置实例变量的值
    object_setIvar(self, nameIvar, name);
}

static void setName(id self, SEL _cmd, id name) //self和_cmd是必须的，在之后可以随意添加其他参数
{
    NSLog(@"static setName called");
    
    // 获取实例变量
    Ivar nameIvar = class_getInstanceVariable([self class], "name");
    // 设置实例变量的值
    object_setIvar(self, nameIvar, name);
}

#pragma mark - 测试方法
- (void)firstMethod {
    NSLog(@"firstMethod");
}

- (void)secondMethod {
    NSLog(@"secondMethod");
}

- (void)thirdMethod {
    NSLog(@"thirdMethod");
}

- (void)fourthMethod {
    NSLog(@"fourthMethod");
}

- (NSString *)filePath
{
    NSString *archiverFilePath = [NSString stringWithFormat:@"%@/archiver", NSHomeDirectory()];
    return archiverFilePath;
}


/*
 struct objc_class {
 Class isa  OBJC_ISA_AVAILABILITY;
 
 #if !__OBJC2__
 Class super_class                       OBJC2_UNAVAILABLE;  // 父类
 const char *name                        OBJC2_UNAVAILABLE;  // 类名
 long version                            OBJC2_UNAVAILABLE;  // 类的版本信息，默认为0
 long info                               OBJC2_UNAVAILABLE;  // 类信息，供运行期使用的一些位标识
 long instance_size                      OBJC2_UNAVAILABLE;  // 该类的实例变量大小
 struct objc_ivar_list *ivars            OBJC2_UNAVAILABLE;  // 该类的成员变量链表
 struct objc_method_list **methodLists   OBJC2_UNAVAILABLE;  // 方法定义的链表
 struct objc_cache *cache                OBJC2_UNAVAILABLE;  // 方法缓存
 struct objc_protocol_list *protocols    OBJC2_UNAVAILABLE;  // 协议链表
 #endif
 
 } OBJC2_UNAVAILABLE;
 
 >>为什么Class的第一个成员也是Class呢，它的内存布局岂不是和底下的object一样了？其实这就是类对象（class object）与实例对象（instance object）的区别了。
 Object-C对类对象与实例对象中的 isa 所指向的类结构作了不同的命名：类对象中的 isa 指向类结构被称作 metaclass，metaclass 存储类的static类成员变量与static类成员方法（+开头的方法）；实例对象中的 isa 指向类结构称作 class（普通的），class 结构存储类的普通成员变量与普通成员方法（-开头的方法）.
 
 **************
 
 struct objc_object {
 Class isa  OBJC_ISA_AVAILABILITY;
 };
 
 typedef struct objc_object *id;
 
 >> id可以用来表示任意一个对象，它是一个 objc_object 结构类型的指针，其第一个成员是一个 objc_class 结构类型的指针。
 一个对象（Object）的isa指向了这个对象的类（Class），而这个对象的类（Class）的isa指向了metaclass。这样我们就可以找到静态方法和变量了。
 
 **************
 
 // 获取类中指定名称实例成员变量的信息
 Ivar class_getInstanceVariable ( Class cls, const char *name );
 
 // 获取类成员变量的信息
 Ivar class_getClassVariable ( Class cls, const char *name );
 
 // 添加成员变量
 BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );
 
 // 获取实例方法
 Method class_getInstanceMethod ( Class cls, SEL name );
 
 // 获取类方法
 Method class_getClassMethod ( Class cls, SEL name );
 */

@end
