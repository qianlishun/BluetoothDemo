# BluetoothDemo
Bluetooth SDK(demo) for iOS 

* 这个 demo 的结构其实是有问题的，当时是为了需求写成这种结构。
* 其实所有的事情都应该由 manager 管理，对于这个结构来说就是把 Driver 和 Device 都合到 manager 中去，
* driver 这个类可以删除掉，device只负责用来表述 peripheral。

* Func
  * Scan for peripheral
  * List  of peripherals that have been found
  * List services of peripheral
  * Connect to peripheral


* Use

   * Creat Manager

             // Manager
             bleManager = [BLEManager sharedInstance];
             // 设置代理
             [bleManager setDelegate:self];


   * Start Scan
      
             // 设置代理
             [bleManager setDelegate:self];

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
              [device disconnect];

   * BLEManager Delegate

              /// 获取周边设备
              - (void)onDeviceFound:(NSArray *)deviceArray{ }

              /// 链接设备的回调
              - (void)isConnected:(BOOL)isConnected withDevice:(BLEDevice *)device{ }

              /// 断开连接的回调
              - (void)disconnected:(BLEDevice *)device{ }

    
