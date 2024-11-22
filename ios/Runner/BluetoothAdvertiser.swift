import CoreBluetooth

@objc class BluetoothAdvertiser: NSObject {
    private var peripheralManager: CBPeripheralManager?

    @objc func startAdvertising() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
}

extension BluetoothAdvertiser: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            let advertisementData = [
                CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "1234")],
                CBAdvertisementDataLocalNameKey: "Find My Device"
            ] as [String : Any]


              
            peripheral.startAdvertising(advertisementData)
            SwiftBluetoothPlugin.channel.invokeMethod("advertisementData", arguments: advertisementData)

                    
        }
    }
}

@objc class SwiftBluetoothPlugin: NSObject, FlutterPlugin {
    static var channel: FlutterMethodChannel!
    private var bluetoothAdvertiser: BluetoothAdvertiser?

    @objc(registerWithRegistrar:) static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.find_my_device/bluetooth", binaryMessenger: registrar.messenger())
        let instance = SwiftBluetoothPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    @objc(handleMethodCall:result:) func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "startAdvertising" {
            BluetoothAdvertiser().startAdvertising()
            
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
