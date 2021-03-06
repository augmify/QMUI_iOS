//
//  UIViewController+QMUI.m
//  qmui
//
//  Created by QQMail on 16/1/12.
//  Copyright © 2016年 QMUI Team. All rights reserved.
//

#import "UIViewController+QMUI.h"
#import "QMUINavigationController.h"
#import <objc/runtime.h>
#import "QMUICommonDefines.h"

@implementation UIViewController (QMUI)

void qmui_loadViewIfNeeded (id current_self, SEL current_cmd) {
    // 主动调用 self.view，从而触发 loadView，以模拟 iOS 9.0 以下的系统 loadViewIfNeeded 行为
    QMUILog(@"%@", ((UIViewController *)current_self).view);
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 兼容 iOS 9.0 以下的版本对 loadViewIfNeeded 方法的调用
        if (![[UIViewController class] instancesRespondToSelector:@selector(loadViewIfNeeded)]) {
            Class metaclass = [self class];
            BOOL success = class_addMethod(metaclass, @selector(loadViewIfNeeded), (IMP)qmui_loadViewIfNeeded, "v@:");
            QMUILog(@"%@ %s, success = %@", NSStringFromClass([self class]), __func__, StringFromBOOL(success));
        }
    });
}

- (UIViewController *)previousViewController {
    if (self.navigationController.viewControllers && self.navigationController.viewControllers.count > 1 && self.navigationController.topViewController == self) {
        NSUInteger count = self.navigationController.viewControllers.count;
        return (UIViewController *)[self.navigationController.viewControllers objectAtIndex:count - 2];
    }
    return nil;
}

- (NSString *)previousViewControllerTitle {
    UIViewController *previousViewController = [self previousViewController];
    if (previousViewController) {
        return previousViewController.title;
    }
    return nil;
}

- (BOOL)isTransitioningTypePresented {
    if (self.navigationController && [self.navigationController.viewControllers indexOfObject:self] > 0) {
        return NO;
    }
    if (self.presentingViewController) {
        // 单纯一个普通viewController被present（其实即使这个viewcontroller被抱在navController或者tabController里面，这里有也值）
        // 所以大部分情况在这里就返回YES了
        return YES;
    }
    return NO;
}

- (UIViewController *)visibleViewControllerIfExist {
    
    if (self.presentedViewController) {
        return [self.presentedViewController visibleViewControllerIfExist];
    }
    
    if ([self isKindOfClass:[UINavigationController class]]) {
        return [((UINavigationController *)self).topViewController visibleViewControllerIfExist];
    }
    
    if ([self isKindOfClass:[UITabBarController class]]) {
        return [((UITabBarController *)self).selectedViewController visibleViewControllerIfExist];
    }
    
    if ([self isViewLoaded] && self.view.window) {
        return self;
    } else {
        NSLog(@"visibleViewControllerIfExist:，找不到可见的viewController。self = %@, self.view.window = %@", self, self.view.window);
        return nil;
    }
}

- (BOOL)respondQMUINavigationControllerDelegate {
    return [[self class] conformsToProtocol:@protocol(QMUINavigationControllerDelegate)];
}

- (BOOL)isViewLoadedAndVisible {
    return self.isViewLoaded && self.view.window;
}

@end
