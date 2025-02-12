import SwiftUI
import Foundation
import Combine
import CoreBluetooth
import LiveViewNative

final class BLEAdapter: NSObject, ObservableObject {
    
    static let shared: BLEAdapter = {
        let instance = BLEAdapter()
        // setup code
        return instance
    }()
    
    let  scanStateChangedEvent = PassthroughSubject<ScanStateEnum?, Never>()
    let  centralStateChangedEvent = PassthroughSubject<CentralStateEnum?, Never>()
    let  peripheralDiscoveredEvent = PassthroughSubject<(PeripheralDisplayData, Int), Never>()
    let  peripheralConnectedEvent = PassthroughSubject<PeripheralDisplayData?, Never>()
    let  peripheralDisconnectedEvent = PassthroughSubject<PeripheralDisplayData?, Never>()
    let  peripheralRSSIUpdateEvent = PassthroughSubject<(String, Int), Never>()
    
    let  serviceDiscoveredEvent = PassthroughSubject<ServiceDisplayData?, Never>()
    let  characteristicsDiscoveredEvent = PassthroughSubject<CharacteristicsDiscoveryDisplayData, Never>()
    let  characteristicValueChangedEvent = PassthroughSubject<CharacteristicValueDisplayData?, Never>()
    
    var scanState = ScanStateEnum.stopped
    
    var scanTimer: Timer?
    
    let bleCommandRegistry = BLECommandRegistry()
    
    var bleManager = BluetoothManager()
    private var cancellables: Set<AnyCancellable> = [] // Store Combine subscriptions
    
    override init() {
        super.init()
        
        bleCommandRegistry.register(commandName: "start_scan") { parameters in
            self.startScan()
        }
        
        bleCommandRegistry.register(commandName: "stop_scan") { parameters in
            self.stopScan()
        }
        
        bleCommandRegistry.register(commandName: "connect_peripheral") { parameters in
            self.stopScan()
        }
        
        bleManager.didStateChange
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] (state) in
                //self?.scanState =
                self?.handleDidStateChange(state)
            }
            .store(in: &cancellables)
        
        bleManager.didDiscoverPeripheral
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] (peripheral, rssi) in
                self?.handleDidDiscoverPeripheral(peripheral, rssi)
            }
            .store(in: &cancellables)
        
        bleManager.didConnectPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripheral in
                self?.handleDidConnectPeripheral(peripheral)
            }
            .store(in: &cancellables)
        
        bleManager.didDisconnectPeripheral
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripheral in
                self?.handleDidDisconnectPeripheral(peripheral)
            }
            .store(in: &cancellables)
        
        
        bleManager.didDiscoverService
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (peripheral, service) in
                self?.handleDidDiscoverService(peripheral, service)
            }
            .store(in: &cancellables)
        
        
        bleManager.didDiscoverCharacteristics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (peripheral, service, characteristics) in
                self?.handleDidDiscoverCharacteristics(peripheral, service, characteristics)
            }
            .store(in: &cancellables)
        
        
        
        bleManager.didReceiveData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (peripheral, characteristicUUID, value) in
                self?.handleDidReceiveData(peripheral, characteristicUUID, value)
            }
            .store(in: &cancellables)
        bleManager.didUpdateRSSI
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (peripheral, rssi) in
                self?.handleDidUpdateRSSI(peripheral, rssi)
            }
            .store(in: &cancellables)
         
    }
    
    func handleBLECommand(payload: [String: Any]) {
        /*guard let command = bleCommandRegistry.parseBLECommand(payload: payload) else {
         print("Error: Invalid BLE command payload.")
         return
         }
         bleCommandRegistry.execute(command: command)
         */
        print("handleBLECommand \(payload)")
    }
    
    func startScan(duration: TimeInterval = 2) {
        /*scanTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            guard let bleManager = self.bleManager as? BluetoothManager else { return }
            self.bleManager.stopScan()
            //self.scanState = .stopped
            //self.scanStateChangedEvent.send(scanState)
        }
        */
        print("BLEAdapter: Start scan")
        scanState = .scanning
        scanStateChangedEvent.send(scanState)
        bleManager.scanForPeripherals(services: BluetoothUtils.stringToCBUUIDArray(uuid_strings: BluetoothUtils.defaultServiceUUIDs))
    }
    
    func stopScan() {
        print("BLEAdapter: Stop scan")
        scanTimer?.invalidate()
        scanState = .stopped
        scanStateChangedEvent.send(scanState)
        bleManager.stopScan()
    }
    
    func getConnectedPeripherals(identifiers: [String]) -> [PeripheralDisplayData] {
        
        let peripherals = bleManager.getKnownPeripherals(identifiers: BluetoothUtils.stringToUUIDArray(uuid_strings: identifiers))
        return peripherals.map { peripheral in
            PeripheralDisplayData(peripheral: peripheral)
        }
    }
    
    func connect(peripheral_uuid: String) {
        print("BLEAdapter: Connect \(peripheral_uuid)")
        bleManager.connect(peripheral_uuid: UUID(uuidString: peripheral_uuid)!)
    }
    
    func disconnect(peripheral_uuid: String) {
        print("BLEAdapter: Disconnect \(peripheral_uuid)")
        bleManager.disconnect(peripheral_uuid: UUID(uuidString: peripheral_uuid)!)
    }
    
    private func handleDidStateChange(_ state: CBManagerState) {
        print("BLEAdapter: State changed \(state)")
        centralStateChangedEvent.send( mapManagerStateToEnum(state: state) )
    }
    
    private func handleDidDiscoverPeripheral(_ peripheral: CBPeripheral, _ rssi: NSNumber) {
        print("BLEAdapter: Discovered \(peripheral.name ?? "Unknown Device") RSSI: \(rssi)")
        peripheralDiscoveredEvent.send((PeripheralDisplayData.init(peripheral: peripheral, rssi: rssi.intValue), rssi.intValue))
    }
    
    private func handleDidConnectPeripheral(_ peripheral: CBPeripheral) {
        print("BLEAdapter: Connected to \(peripheral.name ?? "Unknown Device") state: \(peripheral.state)")
        peripheralConnectedEvent.send(PeripheralDisplayData.init(peripheral: peripheral))
    }
    
    private func handleDidDisconnectPeripheral(_ peripheral: CBPeripheral) {
        print("BLEAdapter: Disconnected from \(peripheral.name ?? "Unknown Device")")
        peripheralDisconnectedEvent.send(PeripheralDisplayData.init(peripheral: peripheral))
    }
    
    private func handleDidDiscoverService(_ peripheral: CBPeripheral, _ service: CBService) {
        print("BLEAdapter: discovered service \(BluetoothUtils.name(for: service.uuid)) on \(peripheral.name ?? "Unknown Device")")
        serviceDiscoveredEvent.send(ServiceDisplayData.init(peripheral: peripheral, service: service))
    }
    
    private func handleDidDiscoverCharacteristics(_ peripheral: CBPeripheral, _ service: CBService, _ characteristics: [CBCharacteristic]) {
        print("BLEAdapter: discovered characteristics on service: \(BluetoothUtils.name(for: service.uuid)) on peripheral: \(peripheral.name ?? "Unknown Device") \(characteristics)")
        
        let characteristicsDisplayData: [CharacteristicDisplayData] = characteristics.map {
            characteristic in
            CharacteristicDisplayData.init(peripheral: peripheral, service: service, characteristic: characteristic)
        }
        
        let characteristicsDiscoveryData = CharacteristicsDiscoveryDisplayData.init(peripheralId: peripheral.identifier.uuidString, serviceId: service.uuid.uuidString, characteristics: characteristicsDisplayData)
        
        
        characteristicsDiscoveredEvent.send(characteristicsDiscoveryData)
        //peripheralDisconnectedEvent.send(PeripheralDisplayData.init(peripheral: peripheral))
    }
    
    private func handleDidReceiveData(_ peripheral: CBPeripheral, _ characteristicUUID: CBUUID, _ value: CharacteristicValue) {
        //print("BLEAdapter: Received data from \(peripheral.name ?? "Unknown Device"), characteristic: \(characteristicUUID), value: \(value)")
        characteristicValueChangedEvent.send(CharacteristicValueDisplayData.init(peripheral: peripheral, characteristicUUID: characteristicUUID, value: value))
    }
    
    private func handleDidUpdateRSSI(_ peripheral: CBPeripheral, _ rssi: NSNumber) {
        print("BLEAdapter: didUpdateRSSI from \(peripheral.name ?? "Unknown Device") RSSI: \(rssi)")
        peripheralRSSIUpdateEvent.send((peripheral.identifier.uuidString, rssi.intValue))
    }
    
    deinit{
        for cancellable in cancellables{
            cancellable.cancel()
        }
    }
}

func mapManagerStateToEnum(state: CBManagerState) -> CentralStateEnum {
    switch state {
    case .poweredOn:
        return .poweredOn
    case .poweredOff:
        return .poweredOff
    case .unauthorized:
        return .unauthorized
    case .unsupported:
        return .unsupported
    case .unknown:
        return .unknown
    case .resetting:
        return .resetting
    @unknown default:
        return .unknown // Or handle the unexpected case in a better way
    }
}


func mapManagerStateToEnum(state: CBPeripheralState) -> PeripheralStateEnum {
    switch state {
    case .disconnected:
        return .disconnected
    case .connecting:
        return .connecting
    case .connected:
        return .connected
    case .disconnecting:
        return .disconnecting
    @unknown default:
        return .disconnected // Or handle the unexpected case in a better way
    }
}

enum CentralStateEnum: String, Codable, Equatable {
    case poweredOn
    case poweredOff
    case unauthorized
    case unsupported
    case unknown
    case resetting
}

enum ScanStateEnum: String, Codable, Equatable {
    case scanning
    case stopped
}

enum PeripheralStateEnum: String, Codable {
    case disconnected, connecting, connected, disconnecting, unknown
}

struct PeripheralDisplayData: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    var rssi: Int
    let state: PeripheralStateEnum
    
    enum CodingKeys: String, CodingKey {
        case id, name, rssi, state
    }
    
    init(peripheral: CBPeripheral, rssi: Int? = 0) {
        self.id = peripheral.identifier.uuidString
        self.name = peripheral.name ?? "Unnamed Peripheral"
        self.state = mapManagerStateToEnum(state: peripheral.state)
        self.rssi = rssi!
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.state = try container.decode(PeripheralStateEnum.self, forKey: .state)
        self.rssi = try container.decode(Int.self, forKey: .rssi)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(state, forKey: .state)
        try container.encode(rssi, forKey: .rssi)
    }
}

struct ServiceDisplayData: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let isPrimary: Bool
    let peripheralID: String
    //let characteristics: [CharacteristicDisplayData]

    init(peripheral: CBPeripheral, service: CBService) {
        self.id = service.uuid.uuidString
        self.name = BluetoothUtils.name(for: service.uuid) // Or fetch a more descriptive name
        self.isPrimary = service.isPrimary
        self.peripheralID = peripheral.identifier.uuidString
        //self.characteristics = [] // Initialize empty; you'd populate this later
    }

    // MARK: - Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isPrimary = try container.decode(Bool.self, forKey: .isPrimary)
        peripheralID = try container.decode(String.self, forKey: .peripheralID)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isPrimary = "is_primary"
        case peripheralID = "peripheral_id"
    }
}

struct CharacteristicsDiscoveryDisplayData: Hashable, Equatable, Codable {
    let peripheralId: String
    let serviceId: String
    let characteristics: [CharacteristicDisplayData]

    init(peripheralId: String, serviceId: String, characteristics: [CharacteristicDisplayData]) {
        self.peripheralId = peripheralId
        self.serviceId = serviceId
        self.characteristics = characteristics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        peripheralId = try container.decode(String.self, forKey: .peripheralId)
        serviceId = try container.decode(String.self, forKey: .serviceId)
        characteristics = try container.decode([CharacteristicDisplayData].self, forKey: .characteristics)
    }

    enum CodingKeys: String, CodingKey {
        case peripheralId = "peripheral_id"
        case serviceId = "service_id"
        case characteristics
    }
}

struct CharacteristicDisplayData: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let peripheralName: String
    let peripheralID: String
    let serviceID: String
    let uuid: String
    let name: String

    // MARK: - Bluetooth Initializer
    init(peripheral: CBPeripheral, service: CBService, characteristic: CBCharacteristic) {
        self.id = characteristic.uuid.uuidString
        self.peripheralName = peripheral.name ?? "Unnamed Peripheral"
        self.peripheralID = peripheral.identifier.uuidString
        self.serviceID = service.uuid.uuidString
        self.uuid = characteristic.uuid.uuidString
        self.name = BluetoothUtils.name(for: characteristic.uuid) // Or fetch a more descriptive name
    }

    // MARK: - Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        peripheralName = try container.decode(String.self, forKey: .peripheralName)
        peripheralID = try container.decode(String.self, forKey: .peripheralID)
        serviceID = try container.decode(String.self, forKey: .serviceID)
        uuid = try container.decode(String.self, forKey: .uuid)
        name = try container.decode(String.self, forKey: .name)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case peripheralName = "peripheral_name"
        case peripheralID = "peripheral_id"
        case serviceID = "service_id"
        case uuid
        case name
    }
}

struct CharacteristicValueDisplayData: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let timestamp: TimeInterval
    let peripheralName: String
    let peripheralID: String
    let characteristicID: String
    let name: String
    let value: CharacteristicValue

    // MARK: - Bluetooth Initializer
    init(peripheral: CBPeripheral, characteristicUUID: CBUUID, value: CharacteristicValue) {
        self.id = peripheral.identifier.uuidString
        self.timestamp = Date().timeIntervalSince1970
        self.peripheralName = peripheral.name ?? "Unnamed Peripheral"
        self.peripheralID = peripheral.identifier.uuidString
        self.characteristicID = characteristicUUID.uuidString
        self.name = BluetoothUtils.name(for: characteristicUUID)
        self.value = value
    }

    // MARK: - Decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        timestamp = try container.decode(TimeInterval.self, forKey: .timestamp)
        peripheralName = try container.decode(String.self, forKey: .peripheralName)
        peripheralID = try container.decode(String.self, forKey: .peripheralID)
        characteristicID = try container.decode(String.self, forKey: .characteristicID)
        name = try container.decode(String.self, forKey: .name)
        value = try container.decode(CharacteristicValue.self, forKey: .value)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case peripheralName = "peripheral_name"
        case peripheralID = "peripheral_id"
        case characteristicID = "characteristic_id"
        case name
        case value
    }
}


enum CharacteristicValue: Hashable, Codable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case data(Data) // Add data type

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        }  else if let dataValue = try? container.decode(Data.self) {
            self = .data(dataValue)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not decode CharacteristicValue"
                )
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let stringValue):
            try container.encode(stringValue)
        case .int(let intValue):
            try container.encode(intValue)
        case .double(let doubleValue):
            try container.encode(doubleValue)
        case .bool(let boolValue):
            try container.encode(boolValue)
        case .data(let dataValue):
             try container.encode(dataValue)
        }
    }
    var description: String {
        switch self {
        case .string(let stringValue):
            return stringValue
        case .int(let intValue):
            return String(intValue)
        case .double(let doubleValue):
            return String(doubleValue)
        case .bool(let boolValue):
            return String(boolValue)
        case .data(let dataValue):
            return dataValue.map { String(format: "%02X", $0) }.joined() // converts and prints hexadecimal string
        }
    }
}
