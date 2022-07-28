# BluetoothDemo
Bluetooth SDK(demo) for iOS 
* 重构了 BLEManager，所有事件都交予 Manager 处理
* 本 demo 只提供了设备基本信息功能的读取，具体设备的服务和功能要根据蓝牙设备的协议来写
* 实现方法和基本信息功能的实现基本是一致的，可以对照 basic func 来写
* 蓝牙实现的流程主要为 搜索发现设备 - 连接设备 - 搜索设备服务 - 监听服务 - 获得回调消息/发送消息
* 实现蓝牙功能主要用到两个CBCentralManager的两个协议：CBCentralManagerDelegate 和 CBPeripheralDelegate。

## Func
  * Scan for peripheral
  * List of peripherals that have been found
  * List services of peripheral
  * Connect to peripheral
  * Listen services
  * Receive/send message


## CBCentralManagerDelegate  

该协议定义了代理对象 CBCentralManager 的一些方法,用来搜索,链接,检索设备的服务等.  

① - centralManagerDidUpdateState: 当central管理器更新状态时调用，这个方法是必须实现的。  
当状态改变为CBCentralManagerStatePoweredOff时,会结束当前的寻找以及断开当前连接的peripheral.  
当检测到PoweredOff时,所有的APP重新开始检索以及寻找peripheral.  

② -centralManager:didDiscoverPeripheral:advertisementData:RSSI: 当central扫描时发现了一个peripheral时调用  

③ -centralManager:didConnectPeripheral:当和一个peripheral设备成功建立连接时调用.   

④ -centralManager:didDisconnectPeripheral:error: 当已经与peripheral建立的连接断开时调用.  


## CBPeripheralDelegate:  

① - peripheral: didDiscoverServices: 发现设备服务  

② - peripheral: didDiscoverCharacteristicsForService:error: 发现设备特征  

③ - peripheral: didUpdateValueForCharacteristic:error: 获取设备发送来的数据  


## Use

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
    
