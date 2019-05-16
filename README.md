# BluetoothDemo
Bluetooth SDK(demo) for iOS 
* 重构了 BLEManager，所有事件都交予 Manager 处理
* 本 demo 只提供了设备基本信息功能的读取，具体设备的服务和功能要根据蓝牙设备的协议来写
* 实现方法和基本信息功能的实现基本是一致的，可以对照 basic func 来写


* Func
  * Scan for peripheral
  * List of peripherals that have been found
  * List services of peripheral
  * Connect to peripheral


* Use

   * Creat Manager

             // Manager
             bleManager = [BLEManager sharedInstance];
             // 设置观察者
             [bleManager registeObserver:self];


   * Start Scan

             // 开始扫描 设置过滤
             [bleManager scanForDevice:0];


   * Stop Scan
   
             [bleManager cancelScan];

   * Connect & disConnect
     
             [bleManager connectDevice:device];
             
             [bleManager disconnectDevice:device];

   * Close all connect

             [bleManager  disconnectAllDevices];


   * BLEManager Delegate

            /// 蓝牙开启状态 (BLE_STATE_ON 为开启)
            - (void)onManagerBLEAvailable: (BLEAvailableState)state;
            /**
             * @brief 获取周边设备.
             * @param deviceArray 设备数组.(BlueDevice类型)
             */
            - (void)onManagerDevicesFound:(NSArray*)deviceArray;
            /**
             * @brief 连接设备成功.
             * @param device 对应设备
             */
            - (void)onManagerDeviceConnected:(BLEDevice*)device;
            /**
             * @brief 连接设备失败.
             * @param device 对应设备
             */
            - (void)onManagerDeviceConnectFailed: (BLEDevice*)device;
            /**
             * @brief 连接设备断开.
             * @param device 对应设备
             */
            - (void)onManagerDeviceDisconnected: (BLEDevice*)device;
    
