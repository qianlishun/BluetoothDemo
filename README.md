# BluetoothDemo
Bluetooth SDK(demo) for iOS 

* Use

    * Creat Manager

          /// Manager
          bleManager = [BLEManager sharedInstance];

          // 设置代理
          [bleManager setDelegate:self];
        
        
        
    * Start Scan
    
           // 开始扫描 设置过滤
           [bleManager scanForDevice:0];
    
    * Stop Scan

           [bleManager stopScan];

    * close all connect

           [bleManager  closeAllDevice];
   
    * BLEDevice
  
            // 设置代理
            [device setDelegate:self]; // 必须要给 device 设置代理

            // 连接设备
            [device connect];
            // 断开设备
            [device disconncet];
    
    
   * BLEManager Delegate
    
           获取周边设备 
           -(void)onDeviceFound:(NSArray *)deviceArray{ }

           链接设备的回调
           -(void)isConnected:(BOOL)isConnected withDevice:(BLEDevice *)device{ }

           断开连接的回调
           -(void)disconnected:(BLEDevice *)device{ }
  
  
