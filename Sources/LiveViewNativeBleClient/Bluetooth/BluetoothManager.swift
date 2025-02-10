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
    
    let prefixes = ["Movesense", "WH-", "PressureSensor", "FLexsense", "NordicHRM", "Thingy", "nRF Blinky", "Power"]
    
    var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    var peripheralConnectionState: [UUID: String] = [:] // Track connection state PER peripheral
    
    public var discoveredServices: [UUID: [CBUUID: CBService]] = [:] // [peripheralUUID: [serviceUUID: CBService]]
    public var discoveredCharacteristics: [UUID: [CBUUID: [CBUUID: CBCharacteristic]]] = [:] // [peripheralUUID: [serviceUUID:
    
    let didStartScan = PassthroughSubject<Void, Never>()
    let didStopScan = PassthroughSubject<Void, Never>()
    
    let didStateChange = PassthroughSubject<CBManagerState, Never>()
    
    // Publishers for specific events
    let didDiscoverPeripheral = PassthroughSubject<(CBPeripheral, NSNumber), Never>()
    let didConnectPeripheral = PassthroughSubject<CBPeripheral, Never>()
    let didFailToConnectPeripheral = PassthroughSubject<(CBPeripheral, Error?), Never>()
    let didDisconnectPeripheral = PassthroughSubject<CBPeripheral, Never>()
    let didReceiveData = PassthroughSubject<(CBPeripheral, CBUUID, String), Never>()
    let didUpdateRSSI = PassthroughSubject<CBPeripheral, Never>()
    
    let didDiscoverCharacteristic = PassthroughSubject<(CBPeripheral, CBService, CBCharacteristic), Never>()
    
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
        
        print("BluetoothManager Starting BLE Mocking mode ... ")
        
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
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("BluetoothManager Bluetooth is powered on")
            //scanForPeripherals()
        case .poweredOff:
            print("BluetoothManager Bluetooth is powered off")
        case .unauthorized:
            print("BluetoothManager Bluetooth is unauthorized")
        case .unsupported:
            print("BluetoothManager Bluetooth is unsupported")
        case .unknown:
            print("BluetoothManager Bluetooth is in an unknown state")
        case .resetting:
            print("BluetoothManager Bluetooth is resetting")
        @unknown default:
            print("BluetoothManager Bluetooth connectionState unknown")
        }
        
        didStateChange.send(central.state)
    }
    
    /*func getKnownPeripherals() -> [CBPeripheral] {
        centralManager.retrievePeripherals(withIdentifiers: [])
    }
    
    func getConnectedPeripherals() -> [CBPeripheral] {
        centralManager.retrieveConnectedPeripherals(withServices: [])
    }*/
    
    func scanForPeripherals() {
        
        guard centralManager.state == .poweredOn else {
            print("BluetoothManager BLuetooth not powered on")
            return
        }
        
        guard centralManager.state != .unsupported else {
            print("BluetoothManager BLuetooth not supported")
            return
        }
        
        print("BluetoothManager Scanning for peripherals...")
        discoveredPeripherals.removeAll() // Clear existing peripherals
        centralManager.scanForPeripherals(withServices: nil, options: nil) // Scan all services
        didStartScan.send()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("BluetoothManager Discovered \(peripheral.name ?? "Unknown Device") RSSI: \(RSSI)")
        discoveredPeripherals[peripheral.identifier] = peripheral
        peripheral.delegate = self // Ensure the delegate is set
        //peripheral.readRSSI()
        
        guard let name = peripheral.name, prefixes.contains(where: { name.hasPrefix($0) }) else{
            //print("BluetoothManager Ignoring peripheral \(peripheral.name ?? "Unnamed"), since does not start with a known prefix \(prefixes)")
            return
        }
        
        didDiscoverPeripheral.send((peripheral, RSSI))
        
        if let name = peripheral.name {
            if prefixes.contains(where: { name.hasPrefix($0) }) {
                print("BluetoothManager Discovered and connecting to peripheral: \(peripheral.name ?? "Unnamed"), RSSI: \(RSSI)")
                self.discoveredPeripherals[peripheral.identifier] = peripheral
                centralManager.connect(peripheral, options: nil)
            }}
        else{
            print("BluetoothManager Discovered peripheral: \(peripheral.name ?? "Unnamed"), RSSI: \(RSSI), but not connecting to it.")
        }
    }
    
    func connect(peripheral: CBPeripheral, serviceUUID: CBUUID? = nil, characteristicUUID: CBUUID? = nil) {
        print("BluetoothManager Attempting to connect to \(peripheral.name ?? "Unknown Device")")
        centralManager.stopScan()
        
        peripheral.delegate = self // Ensure the delegate is set
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        peripheralConnectionState[peripheral.identifier] = "Connecting" // Set initial state
        
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("BluetoothManager Successfully connected to: \(peripheral.name ?? "Unknown Device")")
        peripheralConnectionState[peripheral.identifier] = "Connected" // Update state
        if let serviceUUID = serviceUUID {
            peripheral.discoverServices([serviceUUID])
        } else {
            peripheral.discoverServices(nil) //discover all services
        }
        didConnectPeripheral.send(peripheral) // Notify of the connection
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("BluetoothManager Failed to connect to: \(peripheral.name ?? "Unknown Device") with error: \(String(describing: error?.localizedDescription))")
        peripheralConnectionState[peripheral.identifier] = "Failed to Connect" // Update state
        
        
        didFailToConnectPeripheral.send((peripheral, error))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BluetoothManager Disconnected from \(peripheral.name ?? "Unknown Device") with error: \(String(describing: error?.localizedDescription))")
        peripheralConnectionState[peripheral.identifier] = "Disconnected"  // Update state
        didDisconnectPeripheral.send(peripheral)
    }
    
    
    
    /*
     
     Peripheral delegates
     
     */
        
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("BluetoothManager Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        var serviceDictionary: [CBUUID: CBService] = [:] // Dictionary for current peripheral.
        for service in services {
            print("BluetoothManager Discovered service: \(service.uuid) for peripheral: \(peripheral.name ?? "Unnamed")")
            serviceDictionary[service.uuid] = service
            peripheral.discoverCharacteristics(nil, for: service)
        }
        
        discoveredServices[peripheral.identifier] = serviceDictionary

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("BluetoothManager Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        var characteristicsDictionary: [CBUUID: CBCharacteristic] = [:] //dictionary
        
        for characteristic in characteristics {
            print("BluetoothManager \(peripheral.name ?? "Unnamed Peripheral") Discovered characteristic: \(BluetoothUtils.name(for: characteristic.uuid)) Notifying: \(characteristic.isNotifying)")
        
            BluetoothUtils.printCharacteristicProperties(characteristic: characteristic, peripheral: peripheral)
            
            characteristicsDictionary[characteristic.uuid] = characteristic
            
            // initial read for slow notifiers
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            
            // subscribe to notifications
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic) //This method should only becalled on Characteristics that have
            }
            // notify
            didDiscoverCharacteristic.send((peripheral, service, characteristic))
        }
        //This now associates what characteristic to what service on what peripheral
        discoveredCharacteristics[peripheral.identifier]?[service.uuid] = characteristicsDictionary
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("BluetoothManager Error reading value: \(error.localizedDescription)")
            return
        }
        
        guard let data = characteristic.value else {
            print("BluetoothManager No data")
            return
        }
        
        var stringValue: String? = nil
        
        let uuid = characteristic.uuid
        
        let characteristicName = BluetoothUtils.name(for: uuid)
        
        if let decoded = BluetoothUtils.decodeValue(for: uuid, data: data) {
            stringValue = String(describing: decoded) // Convert to string
        } else {
            print("BluetoothManager Cannot decode data from \(uuid.uuidString)")
        }
        
        if let stringValue = stringValue {
            print("BluetoothManager Got characteristics update for \(characteristicName) value: \(stringValue) \(characteristic) ")
            didReceiveData.send((peripheral, characteristic.uuid, stringValue))
        }
    }
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral, error: (any Error)?) {
        print("BluetoothManager Updated RSSI for \(peripheral) RSSI: \(peripheral.rssi)")
        didUpdateRSSI.send(peripheral)
    }
    
    func disconnect(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
        didDisconnectPeripheral.send(peripheral)
    }
    
    func stopScan() {
        centralManager.stopScan()
        didStopScan.send()
    }
    
}
