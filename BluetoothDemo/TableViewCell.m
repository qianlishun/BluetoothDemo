//
//  TableViewCell.m
//
//  Created by mrq on 16/9/20.
//  Copyright © 2016年 Sonoptek. All rights reserved.
//



#import "TableViewCell.h"
#import "BLEDevice.h"

@interface TableViewCell()

@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UILabel *serviceCountLabel;
@property (nonatomic,strong) UILabel *RSSILabel;

@end

@implementation TableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self customUI];
    }
    return self;
}

#pragma mark - Public Method
- (void)setDevice:(BLEDevice *)device
{
    _nameLabel.text = _serviceCountLabel.text = _RSSILabel.text = @"";
    if (device) {
        [_nameLabel setText:device.name];
        [_serviceCountLabel setText:[NSString stringWithFormat:@" %@ 个services",device.serviceCount]];
        [_RSSILabel setText:[NSString stringWithFormat:@"RSSI:%@",device.RSSI]];
    }
}
- (void)prepareForReuse{
    [super prepareForReuse];
    [self customUI];
}
- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark - UI
- (void)customUI
{
    [self initWithNameLabel];
    [self initWithServiceLabel];
    [self initWithRSSILabel];
    
    [self layoutSubviews];
}

- (void)initWithNameLabel
{
    if (!_nameLabel) {
        _nameLabel = [self customLabelWithFrame:CGRectMake(10.0, 5.0, 100.0, 20.0)];
    }
    if (_nameLabel && _nameLabel.superview != self.contentView) {
        [self.contentView addSubview:_nameLabel];
    }
}

- (void)initWithServiceLabel{
    if (!_serviceCountLabel) {
        _serviceCountLabel = [self customLabelWithFrame:CGRectMake(10, 23.0, 100.0, 20.0)];
    }
    
    if (_serviceCountLabel && _serviceCountLabel.superview != self.contentView) {
        [self.contentView addSubview:_serviceCountLabel];
    }
    [_serviceCountLabel setFont:[UIFont systemFontOfSize:12.0]];
    [_serviceCountLabel setTextColor:[UIColor lightGrayColor]];
}

- (void)initWithRSSILabel
{
    if (!_RSSILabel) {
        _RSSILabel = [self customLabelWithFrame:CGRectMake(self.contentView.bounds.size.width-100, 5.0, 100.0, 30.0)];
    }
    if (_RSSILabel && _RSSILabel.superview != self.contentView) {
        [self.contentView addSubview:_RSSILabel];
    }
    [_RSSILabel setTextAlignment:NSTextAlignmentRight];
}


- (UILabel *)customLabelWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:NSTextAlignmentLeft];
    [label setFont:[UIFont systemFontOfSize:15.0]];
    return label;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [_nameLabel setFrame:CGRectMake(10.0, 5.0, 100.0, 20.0)];
    [_serviceCountLabel setFrame:CGRectMake(10, 23.0, 100.0, 20.0)];
    [_RSSILabel setFrame:CGRectMake(self.contentView.bounds.size.width-100, 5.0, 100.0, 30.0)];
}

@end
