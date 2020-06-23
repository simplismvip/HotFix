//
//  ViewController.m
//  HotFix
//
//  Created by JunMing on 2020/6/22.
//  Copyright © 2020 JunMing. All rights reserved.
//

#import "ViewController.h"
#import "HFTool.h"
#import "HFManager.h"

@interface ViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) HFTestClass *testClass;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSObject
    self.testClass = [HFTestClass new];
    self.dataSource = [@[@"替换崩溃实例方法：instanceMethodCrash",@"替换崩溃类方法：classMethodCrash",@"修改参数：changePrames",@"调用方法：runClassMethod",@"调用方法：runClassMethod前先调用其他方法：Log方法"] mutableCopy];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:(UITableViewStylePlain)];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"hotfix"];
    [self.view addSubview:_tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hotfix"];
    if (!cell) { cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"fix"];}
    cell.textLabel.text = self.dataSource[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        NSString *jsString = [HFTool jsFile:@"instanceMethodCrash"];
        [HFManager evalString:jsString];
        [_testClass instanceMethodCrash:nil];
    }else if (indexPath.row == 1) {
        NSString *jsString = [HFTool jsFile:@"instanceMethodReplace"];
        [HFManager evalString:jsString];
        [_testClass instanceReplace:@"我被替换了"];
    }else if (indexPath.row == 2) {
        NSString *jsString = [HFTool jsFile:@"changePrames"];
        [HFManager evalString:jsString];
        [_testClass changePrames:@"😭😭😭我被改成了"];
    }else if (indexPath.row == 3) {
        NSString *jsString = [HFTool jsFile:@"instanceRunMethod"];
        [HFManager evalString:jsString];
    }else if (indexPath.row == 4) {
        NSString *jsString = [HFTool jsFile:@"runMethodBefore"];
        [HFManager evalString:jsString];
        [_testClass runBefore:@"😁😁😁快看看我之前是否调用了Log方法"];
    }
}

@end
