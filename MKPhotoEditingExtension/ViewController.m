//
//  ViewController.m
//  MKPhotoEditingExtension
//
//  Created by DONLINKS on 16/6/23.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSLog(@"%@", kCIInputRadiusKey);
    NSLog(@"%@", [CIFilter filterNamesInCategory:kCICategoryBuiltIn]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
