//
//  TableViewCell.h
//  BLEDemo
//
//  Created by mrq on 16/9/20.
//  Copyright © 2016年 MrQ. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BLEDevice;
@interface TableViewCell : UITableViewCell

- (void)setDevice:(BLEDevice *)device;

@end
