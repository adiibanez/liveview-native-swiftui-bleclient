import SwiftUI
import Foundation
import Combine
import CoreBluetooth

#if targetEnvironment(simulator) && (os(iOS) || os(watchOS))
import CoreBluetoothMock
#endif

// MARK: - Bluetooth Manager (Core Bluetooth Logic)

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var centralManager: CBCentralManager!
    
    @Published var dataUpdate: String = ""
    
    // Published properties for external observation
    @Published public var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    @Published public var peripheralConnectionState: [UUID: String] = [:] // Track connection state PER peripheral
    @Published public var sensorData: String = "No Data"
    
    // Data - Track services/characteristics PER PERIPHERAL
    @Published public var discoveredServices: [UUID: [CBUUID: CBService]] = [:] // [peripheralUUID: [serviceUUID: CBService]]
    @Published public var discoveredCharacteristics: [UUID: [CBUUID: [CBUUID: CBCharacteristic]]] = [:] // [peripheralUUID: [serviceUUID:
    //@Published public var characteristicValueUpdate:
    // Publishers for specific events
    let didDiscoverPeripheral = PassthroughSubject<CBPeripheral, Never>()
    let didConnectPeripheral = PassthroughSubject<CBPeripheral, Never>()
    let didDisconnectPeripheral = PassthroughSubject<CBPeripheral, Never>()
    let didReceiveData = PassthroughSubject<(CBPeripheral, CBUUID, String), Never>() // peripheral, characteristic, data
    let didUpdateRSSI = PassthroughSubject<CBPeripheral, Never>()
    
    private var serviceUUID: CBUUID?
    private var characteristicUUID: CBUUID?
    
    var isScanning: Bool {
        centralManager?.isScanning ?? false
    }
    // Options
    var sendData: ((String) -> Void)?
    
    override init() {
        super.init()
        
        
#if targetEnvironment(simulator) && (os(iOS) || os(watchOS))
        if #available(iOS 13.0, *) {
            // Example how the authorization can be set and changed.
            /*
             CBMCentralManagerMock.simulateAuthorization(.notDetermined)
             DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4)) {
             CBMCentralManagerMock.simulateAuthorization(.allowedAlways)
             }
             */
            CBMCentralManagerMock.simulateFeaturesSupport = { features in
                return features.isSubset(of: .extendedScanAndConnect)
            }
        }
        CBMCentralManagerMock.simulateInitialState(.poweredOn)
        CBMCentralManagerMock.simulatePeripherals([blinky, hrm, thingy, powerPack])
        
        // Set up initial conditions.
        blinky.simulateProximityChange(.immediate)
        hrm.simulateProximityChange(.near)
        
        simulateRandomHRMUpdates(hrm: hrm, hrmHeartrateCharacteristic: hrmHeartrateCharacteristic)
        //hrm.simulateValueUpdate(Data([0x01, 0x02]), for: hrmHeartrateCharacteristic )
        thingy.simulateProximityChange(.far)
        
        blinky.simulateReset()
        powerPack.simulateProximityChange(.near)
        
        centralManager = CBMCentralManagerFactory.instance(delegate: self, queue: .main, forceMock: false)
        
#else
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
#endif
        
    }
    
    //MARK: CentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            //scanForPeripherals()
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is unsupported")
        case .unknown:
            print("Bluetooth is in an unknown state")
        case .resetting:
            print("Bluetooth is resetting")
        @unknown default:
            print("Bluetooth connectionState unknown")
        }
    }
    
    func scanForPeripherals() {
        
        guard centralManager.state == .poweredOn else {
            print("BLuetooth not powered on")
            return
        }
        
        guard centralManager.state != .unsupported else {
            print("BLuetooth not supported")
            return
        }
        
        print("Scanning for peripherals...")
        discoveredPeripherals.removeAll() // Clear existing peripherals
        centralManager.scanForPeripherals(withServices: nil, options: nil) // Scan all services
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.name ?? "Unknown Device")")
        discoveredPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self // Ensure the delegate is set
        
        //peripheral.readRSSI()
        
        let prefixes = ["Movesense", "WH-", "PressureSensor", "FLexsense", "NordicHRM", "Thingy", "nRF Blinky", "Power"]
        
        guard let name = peripheral.name, prefixes.contains(where: { name.hasPrefix($0) }) else{
            //print("Ignoring peripheral \(peripheral.name ?? "Unnamed"), since does not start with a known prefix \(prefixes)")
            return
        }
        
        if let name = peripheral.name {
            
            if prefixes.contains(where: { name.hasPrefix($0) }) {
                if let jsonData = try? JSONSerialization.data(withJSONObject: [
                    "peripheral_name": (peripheral.name ?? "Unnamed"),
                    "RSSI": RSSI,
                ], options: []) {
                    dataUpdate = String(data: jsonData, encoding: .utf8) ?? ""
                } else{
                    dataUpdate = "Error serializing data to JSON"
                }
                print("Discovered and connecting to peripheral: \(peripheral.name ?? "Unnamed"), RSSI: \(RSSI)")
                self.discoveredPeripherals[peripheral.identifier] = peripheral
                peripheral.delegate = self // SET DELEGATE BEFORE calling readRSSI()
                Task{
                    //await self.updateRSSI(peripheral: peripheral)
                    //self.updatePeripheralDisplayData()
                }
                //centralManager.stopScan()
                centralManager.connect(peripheral, options: nil)
            }}
        else{
            if let jsonData = try? JSONSerialization.data(withJSONObject: ["peripheral_name": peripheral.name ?? "Unnamed", "RSSI": RSSI], options: []) {
                dataUpdate = String(data: jsonData, encoding: .utf8) ?? ""
            } else{
                dataUpdate = "Error serializing data to JSON"
            }
            print("Discovered peripheral: \(peripheral.name ?? "Unnamed"), RSSI: \(RSSI), but not connecting to it.")
        }
        
        didDiscoverPeripheral.send(peripheral) // Notify of the discovered peripheral
    }
    
    func connect(peripheral: CBPeripheral, serviceUUID: CBUUID? = nil, characteristicUUID: CBUUID? = nil) {
        print("Attempting to connect to \(peripheral.name ?? "Unknown Device")")
        centralManager.stopScan()
        
        peripheral.delegate = self // Ensure the delegate is set
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        peripheralConnectionState[peripheral.identifier] = "Connecting" // Set initial state
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Successfully connected to: \(peripheral.name ?? "Unknown Device")")
        peripheralConnectionState[peripheral.identifier] = "Connected" // Update state
        if let serviceUUID = serviceUUID {
            peripheral.discoverServices([serviceUUID])
        } else {
            peripheral.discoverServices(nil) //discover all services
        }
        didConnectPeripheral.send(peripheral) // Notify of the connection
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to: \(peripheral.name ?? "Unknown Device") with error: \(String(describing: error?.localizedDescription))")
        peripheralConnectionState[peripheral.identifier] = "Failed to Connect" // Update state
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device") with error: \(String(describing: error?.localizedDescription))")
        peripheralConnectionState[peripheral.identifier] = "Disconnected"  // Update state
    }
    
    // MARK: - Peripheral Delegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        var serviceDictionary: [CBUUID: CBService] = [:] // Dictionary for current peripheral.
        for service in services {
            print("Discovered service: \(service.uuid) for peripheral: \(peripheral.name ?? "Unnamed")")
            serviceDictionary[service.uuid] = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        discoveredServices[peripheral.identifier] = serviceDictionary // Assign new dictionary to discoveredServices for this peripheral
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        var characteristicsDictionary: [CBUUID: CBCharacteristic] = [:] //dictionary
        
        for characteristic in characteristics {
            print("\(peripheral.name ?? "Unnamed Peripheral") Discovered characteristic: \(BluetoothUtils.name(for: characteristic.uuid)) Notifying: \(characteristic.isNotifying)")
        
        
            BluetoothUtils.printCharacteristicProperties(characteristic: characteristic, peripheral: peripheral)
            
            characteristicsDictionary[characteristic.uuid] = characteristic
            
            //if(characteristic.isNotifying) {
            
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic) //This method should only becalled on Characteristics that have Notify
            }
            
            if characteristic.properties.contains(.read) {
                //peripheral.readValue(descriptor: characteristic.descriptors)
                peripheral.readValue(for: characteristic)
                //var stringValue = BluetoothUtils.decodeValue(for: characteristic.uuid, data: )
                
                //print("\(BluetoothUtils.name(for: characteristic.uuid)) read value: \(characteristic.value)")
            }
            
            
            
        }
        //This now associates what characteristic to what service on what peripheral
        discoveredCharacteristics[peripheral.identifier]?[service.uuid] = characteristicsDictionary
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error reading value: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("No data")
            return
        }
        
        let sensorName = peripheral.name ?? "Unnamed"
        let characteristicUuid = characteristic.uuid.uuidString
        var stringValue: String? = nil
        
        let uuid = characteristic.uuid
        
        var characteristicName = BluetoothUtils.name(for: uuid)
        
        if uuid == CBUUID(string: "00002a37-0000-1000-8000-00805f9b34fb") {
            stringValue = BluetoothUtils.decodeHeartRate(data: data)
        } else if let decoded = BluetoothUtils.decodeValue(for: uuid, data: data) {
            stringValue = String(describing: decoded) // Convert to string
        } else {
            print("Cannot decode data from \(uuid.uuidString)")
        }
        
        if let stringValue = stringValue {
            print("Got characteristics update for \(characteristicName) value: \(stringValue) \(characteristic) ")
            didReceiveData.send((peripheral, characteristic.uuid, stringValue))
        }
    }
    
    //Disconnect a service.
    func disconnect(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    //Data Structures
    struct PeripheralDisplayData: Identifiable {
        let id: UUID
        let name: String
        let rssi: Int
        let state: CBPeripheralState
        let services: [ServiceDisplayData]
    }
    
    struct ServiceDisplayData: Identifiable {
        let id: UUID
        let name: String
        let characteristics: [CharacteristicDisplayData]
    }
    
    struct CharacteristicDisplayData: Identifiable {
        let id = UUID()
        let uuid: String
        let name: String
    }
    
    struct CharacteristicValueDisplayData: Identifiable {
        let id = UUID()
        let peripheralUUID: UUID
        let characteristicUUID: UUID
        let uuid: String
        let value: String
    }
}
