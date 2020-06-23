# 热更新

很多时候线上出现bug，可能是很小，很细微的。对此我们可能仅仅需要改动一个返回值就能解决线上bug。但是实际上我们并没有这么一套机制去对线上bug进行热修复，只有通过发版才能解决，这样对用户很不友好。

热更新在业界其实还是有很多解决方案的，比如Rollout.io 、 JSpatch、 DynamicCocoa、React Native、 Weex、Wax 、Hybrid都可以实现，但是以上无论是那种原理都是差不多，都是通过JS和OC的相互调用，再利用OC运行时特性修改方法。因为以上可实现热更新的方式有的被苹果禁止上架，比如JSpatch，有的可能需要我们对代码做大量改动才能实现，比如React Native，因此这次分享的热更新方法并不是以上几种，是一种轻量级的热更新方案，虽然功能并没有很完备，但是满足基本使用时没问题的。首先我们先介绍一下实现热更新的两个基本工具。

## JSVirtualMachine（简称JSVM）

一个JSVM实例代表了一个自包含的JS运行环境，或者是一系列JS运行所需的资源。该类有两个主要的使用用途：

1. 一是对JavaScript和Objective-C桥接对象的内存管理，
2. 二是支持并发的JS调用

```objective-c
@interface JSVirtualMachine : NSObject
/* 创建一个新的完全独立的虚拟机 */
(instancetype)init;
/* 对桥接对象进行内存管理 */
- (void)addManagedReference:(id)object withOwner:(id)owner;
/* 取消对桥接对象的内存管理 */
- (void)removeManagedReference:(id)object withOwner:(id)owner;
@end
```

但是每个虚拟机都是完整且独立的，有其独立的堆空间和垃圾回收器（garbage collector ），GC无法处理别的虚拟机堆中的对象，因此你不能把一个虚拟机中创建的值传给另一个虚拟机。JavaScriptCore API都是线程安全的。你可以在任意线程创建JSValue或者执行JS代码，然而，所有其他想要使用该虚拟机的线程都要等待。如果想并发执行JS，需要使用多个不同的虚拟机来实现。

![jscore_04](./jscore_04.png)

### JSContext

JSContext翻译过来就是“上下文”，一个JSContext表示了一次JS的执行环境。我们可以通过创建一个JSContext去调用JS脚本，访问一些JS定义的值和函数，同时也提供了让JS访问Native对象，方法的接口。JSContext和JSVM之间的关系上图可以直观看出，每一个JSContext对象都归属于一个JSVM。每个虚拟机可以包含多个不同的上下文，并允许在这些不同的上下文之间传值（JSValue对象）。

![jscore_05](./jscore_05.png)

JSContent是JS和Native相互访问的桥梁，热更新中为JS调用Native代码提供能力。JSContent执行JS代码是调用evaluateScript函数可以执行一段的JS代码，返回值是JS中最后生成的一个值，用属于当前JSContext中的JSValue（下面会有介绍）。

```objective-c
JSContext *context = [[JSContext alloc] init];
[context evaluateScript:@"var a = 1;var b = 2;"];
NSInteger sum = [[context evaluateScript:@"a + b"] toInt32];
// Output：sum=3
```

另外还可以通过KVC的方式，给JSContext塞进去很多全局对象或者全局函数：

```objective-c
JSContext *context = [[JSContext alloc] init];
context[@"globalFunc"] =  ^() {
        NSArray *args = [JSContext currentArguments];
        for (id obj in args) {
            NSLog(@"拿到了参数:%@", obj);
        }
 };
 context[@"globalProp"] = @"全局变量字符串";
 [context evaluateScript:@"globalFunc(globalProp)"];
// Output：“拿到了参数:全局变量字符串”
```

这是非常重要的特性，著名的JSCore的框架如JSPatch，就是利用了这个特性去更改、替换Native方法实现热更新。JSContext有一个很重要的返回值是JSValue只读属性globalObject，

```objective-c
@property (readonly, strong) JSValue *globalObject;
```

**它返回当前执行JSContext的全局对象，这个全局对象其实也是JSContext最核心的东西，当我们通过KVC方式与JSContext进去取值赋值的时候，实际上都是在跟这个全局对象做交互，几乎所有的东西都在全局对象里。我们把上面代码的context实例的globalObject对象打印出来很直观的看到结果。可以知道JS中的全局变量、全局函数其实就是全局对象的属性和函数。**

![jscore_05](./jscore_06.png)

下面我们介绍一下JS和OC代码调用的执行流程，这也是我们热修复的基础。

```objective-c
// 另一个例子
JSContext *context = [[JSContext alloc] init];
context[@"CGPointMake"] = ^id(JSValue *x, JSValue *y) {
		 return [NSValue valueWithCGPoint:CGPointMake(x.toDouble, y.toDouble)];
};
JSValue *jsValue = [context evaluateScript:@"CGPointMake(100,200)"];
NSLog(@"%@",jsValue);
// Output：NSPoint: {100, 300}

// 简单介绍一下以上代码的执行流程
1、首先执行 context[@"CGPointMake"] = ^id(JSValue *x, JSValue *y) {}。
这段代码功能是在JS中注入函数：CGPointMake(value1,value2) { } 并等待回调。
2、紧接着执行 evaluateScript:@"CGPointMake(100,200)" 这段代码调用上面的JS函数并传入参数(100,200)
3、JS代码调用函数后会回调OC的Block代码执行Block并返回值
4、获得返回值并使用 JSValue *jsValue 接收。
```

### JSValue

JSValue实例是一个指向JS值的引用指针。我们可以使用JSValue类，在OC和JS的基础数据类型之间相互转换。同时我们也可以使用这个类，去创建包装了Native自定义类的JS对象，或者是那些由Native方法或者Block提供实现JS方法的JS对象。

![jscore_07](./jscore_07.png)

同时JSValue也提供了转换的API，下面是其中的几个API详细的可以去看头文件。

```objective-c
+ (JSValue *)valueWithDouble:(double)value inContext:(JSContext *)context;
+ (JSValue *)valueWithInt32:(int32_t)value inContext:(JSContext *)context;
- (NSArray *)toArray;
- (NSDictionary *)toDictionary;
```

### JSExport

JSExport是一个协议，这个协议开放了JS调用OC类方法、实例方法、属性的功能。这里不详细介绍。

### 总结

简单总结一下就是JSCore给Native 提供了JS可以执行的环境，开发者使用JSContext和JSValue这两个类，由JSContext负责提供相互调用的接口，JSValue为这个互相调研提供JS和Native数据类型的桥接转换，达到让JS执行Native并让Native回调JS的目的。

![jscore_08](./jscore_08.png)

### Aspects（OC Hook 框架）

因为JSPatch方案会被拒绝上架，这次分享不同于JSPatch那么强大，是依赖Aspects实现的一套轻量级低风险方案，提供了三种能力：

1. 通过JS代码在任意方法前后注入代码的能力。
2. 通过JS代码替换任意方法实现的能力。
3. 通过JS代码调用任意类/实例方法的能力。

第1、2种能力主要就是通过Aspects实现，因此这里会简单介绍一下Aspects这个开源框架（第三种能力稍后介绍）。

Aspects是一个面向切面编程开源库，允许我们通过运行时消息转发Hook类方法和实例方法，通过预编译和运行期动态代理实现给程序动态统一添加功能，注入代码可以在方法执行前、后执行，也可以替换掉原有的方法。因此满足我们热更新方案中1、2两种能力。

```objective-c
typedef NS_OPTIONS(NSUInteger, AspectOptions) {
    AspectPositionAfter   = 0,   // 方法后调用         
    AspectPositionInstead = 1,   // 方法替换                  
    AspectPositionBefore  = 2,   // 方法前调用                  
};
// Hook类方法
+ (id<AspectToken>)aspect_hookSelector:(SEL)selector
                      withOptions:(AspectOptions)options
                       usingBlock:(id)block
                            error:(NSError **)error;
// Hook实例方法
- (id<AspectToken>)aspect_hookSelector:(SEL)selector
                      withOptions:(AspectOptions)options
                       usingBlock:(id)block
                            error:(NSError **)error;
```

这里不对Aspects的源码做详细解析，我画了一张图片对Aspects的主要流程做简单介绍。Aspects代码不到1000行，使用运行时动态生成hook类的子类，并将当前对象与子类进行关联，然后替换子类中的 forwardInvocation 方法，将当前对象的isa指针指向subclass，同时修改subclass、subclass元类的class方法，使它返回当前对象的class，这里和kvo的实现原理很相似。而且涉及到了很多的isa指针修改、IMP 和 SEL 交换操作，绕了很大一圈。不过如果全部理解后对运行时的理解和使用会有极大帮助，建议有时间可以好好读读源码。

# NSInvocation

NSInvocation是一个消息调用类，它包含了所有OC消息的成分：target、selector、参数、返回值等。NSInvocation可以将消息转换成一个对象，消息的每一个参数能够直接设定，而且当一个NSInvocation对象调度时返回值是可以自己设定的。一个NSInvocation对象能够重复的调度不同的目标(target)，而且它的selector也能够设置为另外一个方法签名。

NSInvocation 这个类完全满足为上面热更新中的第3条“通过JS代码调用任意类/实例方法的能力”。我们可以使用NSInvocation这个类实现调用任意Native代码的能力。

```objective-c
// 获取方法签名
NSMethodSignature *signature = [ViewController instanceMethodSignatureForSelector:@selector(startTest_3:text1:)];
// 生成调用对象
NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
// 设置target
invocation.target = self;
// 设置方法实现
invocation.selector = @selector(startTest_3:text1:);
// 设置参数，参数必须从2开始，第一个第二个参数为target和selector
NSString *argument = @"参数1";
NSString *argument1 = @"参数2";
[invocation setArgument:&argument atIndex:2];
[invocation setArgument:&argument1 atIndex:3];
// 调用
[invocation invoke];
NSString *returnValue = nil;
[invocation getReturnValue:&returnValue];
NSLog(@"返回值：%@",returnValue);

// 被调用方法
- (NSString *)startTest_3:(NSString *)text text1:(NSString *)text1 {
    NSLog(@"参数%@--%@，无返回值：startTest_1",text,text1);
    return @"返回值";
}
```

NSInvocation的使用方式很简单，主要有一下几个步骤：

1. 根据SEL获取方法签名NSMethodSignature 对象，使用方法前面获取NSInvocation 对象。
2. 设置方法调用多参数。
3. 获取方法返回值。

## 热更新

上面铺垫了那么多，终于到正题了。我们按照上面的三个需求来完成依次介绍。下图是文件结构。

![jscore_09](./jscore_09.png)

HotFixmanager类提供的主要方法和属性

```objective-c
@interface MGHFManager : NSObject
// 公共方法，执行JS代码
- (void)evaluateScript:(NSString *)jsString;
// context 属性，这个属性并不暴露出来
@property (nonatomic, strong) JSContext *context;
@end

  // 执行方法，就是调研JSContext类中的一个方法
- (void)evaluateScript:(NSString *)jsString {
    [self.context evaluateScript:jsString withSourceURL:[self getSource]];
}

```

```objective-c
// 修改block方法
_context[@"Block"] = ^id(NSString *blockTypes, JSValue *blockFunc){
  			return [blockFunc callWithArguments:nil];
}
```

### 1、修改类方法

```objective-c
// 修改类方法   
_context[@"fixClassMethod"] =  ^(NSString *className, NSString *selectorName, JSValue *fixImpl) {
         [self fixMethod:className isClass:YES selectorName:selectorName fixImpl:fixImpl];
};

// 修改实例方法
_context[@"fixInstanceMethod"] =  ^(NSString *className, NSString *selectorName, JSValue *fixImpl) {
        [self fixMethod:className isClass:NO selectorName:selectorName fixImpl:fixImpl];
};
```

下面的代码是使用 Aspects 实现修改方法

```objective-c
- (void)fixMethod:(NSString *)clasName isClass:(BOOL)isClass selectorName:(NSString *)selectorName fixImpl:(JSValue *)fixImpl {
    SEL sel = NSSelectorFromString(selectorName);
    Class cls = NSClassFromString(clasName);
    if (isClass) { cls = object_getClass(cls); }
  	// 调用Aspects 替换方法
    [cls aspect_hookSelector:sel withOptions:AspectPositionInstead usingBlock:^(id<AspectInfo_mgs> aspectInfo) {
        [fixImpl callWithArguments:@[aspectInfo.instance, aspectInfo.originalInvocation, aspectInfo.arguments]];
    } error:nil];
}
```

### 2、调用方法

```objective-c
_context[@"InvocationSetArgument"] = ^(NSInvocation *invoke, JSValue *argument, NSInteger index) {
         id arg = argument.toObject;
         [self invocation:invoke setArgument:arg atIndex:index + 2];
}
```

下面的代码是使用 NSInvocation 调用方法

1、设置参数

![jscore_11](./jscore_11.png)

2、设置返回值类型

![jscore_10](./jscore_10.png)

# JSPatch

JSPatch的实现以来OC的动态语言特性，核心部分原理和Aspects十分类似，都是利用OC消息转发机制实现。而且JSPatch对OC方法处理能力十分强大，支持协议Protocol，Property实现，self关键字，super关键字，Struct，C 函数支持等等特性。几乎能支持修改任何原生方法，但是遗憾的是苹果明确禁止JSPatch使用，无法通过审核。另外JSPatch源码就两个文件，不到2000多行代码，有兴趣可以读一读。

