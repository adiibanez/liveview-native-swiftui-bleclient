import SwiftUI
import Foundation
import Combine
import CoreBluetooth
import LiveViewNative

final class BLEAdapter: NSObject, ObservableObject {
    
    @Published var scanStateChanged: ScanStateEnum = .stopped
    @Published var centralStateChanged: CentralStateEnum = .unknown
    
    @Published var peripheralDiscovered: PeripheralDisplayData? = nil
    @Published var peripheralConnected: PeripheralDisplayData? = nil
    @Published var peripheralDisconnected: PeripheralDisplayData? = nil
    @Published var serviceDiscovered: ServiceDisplayData? = nil
    @Published var characteristicDiscovered: CharacteristicDisplayData? = nil
    @Published var characteristicValueChanged: CharacteristicValueDisplayData? = nil
    
    //let bleCommandRegistry = BLECommandRegistry()
    
    var bleManager = BluetoothManager()
    private var cancellables: Set<AnyCancellable> = [] // Store Combine subscriptions
    //var discoveredPeripherals: [UUID: PeripheralDisplayData] = [:] // store objects
    
    override init() {
        super.init()
        
        /*bleCommandRegistry.register(commandName: "start_scan") { parameters in
            self.startScan()
        }
        
        bleCommandRegistry.register(commandName: "stop_scan") { parameters in
            self.stopScan()
        }
         */
        
        bleManager.didStateChange
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] (state) in
                self?.handleDidStateChange(state)
            }
            .store(in: &cancellables)
        
        // Subscribe to BluetoothManager's publishers
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
        
        bleManager.didReceiveData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (peripheral, characteristicUUID, value) in
                self?.handleDidReceiveData(peripheral, characteristicUUID, value)
            }
            .store(in: &cancellables)
        bleManager.didUpdateRSSI
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peripheral in
                self?.handleDidUpdateRSSI(peripheral)
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
    
    func startScan() {
        bleManager.scanForPeripherals()
    }
    
    func stopScan() {
        bleManager.stopScan()
    }
    
    // MARK: - Event Handling Functions
    
    
    private func handleDidStateChange(_ state: CBManagerState) {
        print("BLEAdapter: State changed \(state)")
        centralStateChanged = mapManagerStateToEnum(state: state)
    }
    
    private func handleDidDiscoverPeripheral(_ peripheral: CBPeripheral, _ rssi: NSNumber) {
        print("BLEAdapter: Discovered \(peripheral.name ?? "Unknown Device") RSSI: \(rssi)")
        
        //var serviceArray = serviceDataFromCB(peripheral.services)
        //let newPeripheralData = PeripheralDisplayData.init(peripheral: peripheral, rssi: rssi.intValue, services: serviceArray)
        //let newPeripheralData =
        
        // Update discoveredPeripherals dictionary
        //discoveredPeripherals[peripheral.identifier] = newPeripheralData
        
        peripheralDiscovered = PeripheralDisplayData.init(peripheral: peripheral, rssi: rssi.intValue)
    }
    
    private func handleDidConnectPeripheral(_ peripheral: CBPeripheral) {
        print("BLEAdapter: Connected to \(peripheral.name ?? "Unknown Device")")
        peripheralConnected = PeripheralDisplayData.init(peripheral: peripheral)
        // Start discovering services or characteristics, or anything else
    }
    
    private func handleDidDisconnectPeripheral(_ peripheral: CBPeripheral) {
        print("BLEAdapter: Disconnected from \(peripheral.name ?? "Unknown Device")")
        peripheralDisconnected = PeripheralDisplayData.init(peripheral: peripheral)
        //Clean up anything.
    }
    
    private func handleDidReceiveData(_ peripheral: CBPeripheral, _ characteristicUUID: CBUUID, _ value: String) {
        print("BLEAdapter: Received data from \(peripheral.name ?? "Unknown Device"), characteristic: \(characteristicUUID), value: \(value)")
        characteristicValueChanged = nil
        characteristicValueChanged = CharacteristicValueDisplayData.init(peripheral: peripheral, characteristicUUID: characteristicUUID, value: value)
    }
    
    private func handleDidUpdateRSSI(_ peripheral: CBPeripheral) {
        print("BLEAdapter: didUpdateRSSI from \(peripheral.name ?? "Unknown Device")")
        
        // Update the appropriate PeripheralDisplayData object (either discovered or connected) with the new RSSI value
        /*if var existingData = discoveredPeripherals[peripheral.identifier] {
            existingData.rssi = peripheral.rssi?.intValue ?? 0 // Update RSSI (optional unwrapping)
            discoveredPeripherals[peripheral.identifier] = existingData // Update the dictionary
            peripheralDiscovered = existingData  // Trigger an update to the UI if this value is displayed.
        }*/
        
        
    }
    
    deinit{
        for cancellable in cancellables{
            cancellable.cancel()
        }
    }
}

enum ScanStateEnum {
    case scanning
    case stopped
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


enum CentralStateEnum: Encodable {
    case poweredOn
    case poweredOff
    case unauthorized
    case unsupported
    case unknown
    case resetting
}

enum PeripheralStateEnum: Encodable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/*func serviceDataFromCB(_ services: [CBService]?) -> [ServiceDisplayData] {
    guard let services = services else {
        return [] // Return an empty array if services is nil
    }
    return services.map { ServiceDisplayData(service: $0) }
}*/


struct PeripheralDisplayData: Identifiable, Equatable, Encodable {
    let id: UUID
    let name: String
    var rssi: Int
    let state: PeripheralStateEnum
    //var services: [ServiceDisplayData]
    
    init(peripheral: CBPeripheral) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? "Unnamed Peripheral"
        self.rssi = -128
        self.state = mapManagerStateToEnum(state: peripheral.state)
        //self.services = services
    }
    
    init(peripheral: CBPeripheral, rssi: Int = 0) {
        self.id = peripheral.identifier
        self.name = peripheral.name ?? "Unnamed Peripheral"
        self.rssi = rssi
        self.state = mapManagerStateToEnum(state: peripheral.state)
        //self.services = services
    }
}

struct ServiceDisplayData: Identifiable, Equatable, Encodable {
    let id: UUID
    let name: String
    //let characteristics: [CharacteristicDisplayData]
    
    init(service: CBService) {
        self.id = UUID(uuidString: service.uuid.uuidString)!
        self.name = BluetoothUtils.name(for: service.uuid) // Or fetch a more descriptive name
        //self.characteristics = [] // Initialize empty; you'd populate this later
    }
}

struct CharacteristicDisplayData: Identifiable, Equatable, Encodable {
    let id = UUID()
    let peripheralName: String
    let peripheralID: String
    let uuid: String
    let name: String
    
    init(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        self.peripheralID = peripheral.identifier.uuidString
        self.peripheralName = peripheral.name ?? "Unnamed Peripheral"
        self.uuid = characteristic.uuid.uuidString
        self.name = BluetoothUtils.name(for: characteristic.uuid) // Or fetch a more descriptive name
    }
}

struct CharacteristicValueDisplayData: Identifiable, Equatable, Encodable {
    let id = UUID()
    let peripheralName: String
    let peripheralID: String
    let characteristicUUID: String //Changed to UUID type
    let name: String
    let value: String
    
    init(peripheral: CBPeripheral, characteristicUUID: CBUUID, value: String) {
        self.peripheralID = peripheral.identifier.uuidString
        self.peripheralName = peripheral.name ?? "Unnamed Peripheral"
        self.characteristicUUID = characteristicUUID.uuidString
        self.name = BluetoothUtils.name(for: characteristicUUID) // Or fetch a more descriptive name
        self.value = value
    }
}

extension Encodable {
    func toJsonString() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                print("Failed to convert JSON data to string.")
                return nil
            }
        } catch {
            print("Error encoding to JSON: \(error)")
            return nil
        }
    }
}
