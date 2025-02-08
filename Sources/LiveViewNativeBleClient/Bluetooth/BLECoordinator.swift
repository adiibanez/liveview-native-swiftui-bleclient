import SwiftUI
import Foundation
import Combine
import LiveViewNative
import CoreBluetooth
import LiveViewNativeCore
import LiveViewNativeCoreFFI

final class BLEClientCoordinator: NSObject, ObservableObject {
    @Published var dataUpdate: String = ""
    @Published var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    @Published  var peripheralDisplayData: [BluetoothManager.PeripheralDisplayData] = []
    
    var bleManager = BluetoothManager()
    
    override init() {
        super.init()
    }
    
    func startScan(){
        bleManager.scanForPeripherals()
    }
    
    func stopScan(){
        bleManager.stopScan()
    }
    
    func updatePeripheralDisplayData() {
        
    }
}
