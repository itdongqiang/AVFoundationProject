//
//  TTAVVideoCatlogViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/4/3.
//

#import "TTAVVideoCatlogViewController.h"

@interface TTAVVideoCatlogViewController ()

@property(nonatomic,strong) NSDictionary *catelogItems;
@property(nonatomic,strong) NSDictionary *viewControllerItems;

@end

@implementation TTAVVideoCatlogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return self.catelogItems.allKeys[section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.catelogItems.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.catelogItems[self.catelogItems.allKeys[section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    cell.textLabel.text = self.catelogItems[self.catelogItems.allKeys[indexPath.section]][indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *className = self.viewControllerItems[self.viewControllerItems.allKeys[indexPath.section]][indexPath.row];
    UIViewController *VC = (UIViewController *)[[NSClassFromString(className) alloc] init];
    [self.navigationController pushViewController:VC animated:YES];
}


- (NSDictionary *)catelogItems{
    if (!_catelogItems) {
        _catelogItems = @{@"视频": @[@"1.视频合成/BGM/转场",
                   @"2.贴纸、文字、gif",
        ]};
    }
    return _catelogItems;
}

- (NSDictionary *)viewControllerItems{
    if (!_viewControllerItems) {
        _viewControllerItems = @{@"合成": @[@"TTAVVideoComposition1ViewController",
                   @"TTAVVideoPasterViewController",
        ]};
    }
    return _viewControllerItems;
}

@end
