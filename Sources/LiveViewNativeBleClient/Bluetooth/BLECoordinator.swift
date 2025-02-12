import SwiftUI
import Foundation
import Combine
import CoreBluetooth
import LiveViewNative

final class BLECoordinator: NSObject, ObservableObject {
    
    @AppStorage("knownPeripherals") private var knownPeripheralsData: String = "{}"
    var knownPeripherals: [String: PeripheralDisplayData] {
        get {
            let decoder = JSONDecoder()
            if let data = knownPeripheralsData.data(using: .utf8), // Convert String to Data
               let decoded = try? decoder.decode([String: PeripheralDisplayData].self, from: data) { // Decode the Data
                return decoded
            } else {
                print("Decoding failed") // Add some error logging
                return [:] // Return an empty array if decoding fails
            }
        }
        set {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(newValue), // Encode into Data
               let encodedString = String(data: data, encoding: .utf8) { // Convert Data to String
                knownPeripheralsData = encodedString
            } else {
                print("Encoding failed") // Add some error logging
            }
        }
    }
    
    @Published var peripheralDisplayData: [String: PeripheralDisplayData] = [:]
    @Published var scanState: ScanStateEnum = .stopped
    @Published var bleState: CentralStateEnum = .unknown
    @Published var isScannning: Bool = false
    
    @LiveElementIgnored
    private var cancellables: Set<AnyCancellable> = []
    @LiveElementIgnored
    var peripheralRSSIData: [String: Int] = [:]
    
    func addPeripheral(peripheral: PeripheralDisplayData) {
        peripheralDisplayData[peripheral.id] = peripheral
    }
    
    func removePeripheral(uuid: String) {
        peripheralRSSIData.removeValue(forKey: uuid)
        peripheralDisplayData.removeValue(forKey: uuid)
    }
    
    func toggleScan() {
        if(self.isScannning) {
            BLEAdapter.shared.stopScan()
            isScannning = false
        } else {
            BLEAdapter.shared.startScan()
            isScannning = true
        }
    }
    
    override init() {
        super.init()
        
        BLEAdapter.shared.getConnectedPeripherals(identifiers: BluetoothUtils.defaultServiceUUIDs).forEach{
            peripheralDisplayData[$0.id] = $0
        }
        
        BLEAdapter.shared.scanStateChangedEvent
            .receive(on: RunLoop.main)
            .sink(receiveValue: {
                [weak self] scanState in
                guard let self = self else { return }
                
                guard let scanState = scanState as ScanStateEnum? else {
                    return
                }
                self.isScannning = ( scanState == .scanning )
                self.scanState = scanState
            })
            .store(in: &cancellables)
        //.assign(to: &$scanState)
        
        BLEAdapter.shared.centralStateChangedEvent
            .sink(receiveValue: {
                [weak self] state in
                guard let self = self else { return }
                
                guard let state = state as CentralStateEnum? else {
                    return
                }
                print("BLECoordinator central state change: \(state)")
                self.bleState = state
            })
            .store(in: &cancellables)
        
        BLEAdapter.shared.peripheralDiscoveredEvent
            .sink(receiveValue: {
                [weak self] (peripheral, rssi) in
                guard let self = self else { return }
                
                guard var peripheral = peripheral as PeripheralDisplayData? else {
                    return
                }
                
                print("BLECoordinator new peripheral discovered: \(peripheral) \(rssi)")
                //                self.handlePeripheralConnected(peripheral)
                
                peripheralRSSIData[peripheral.id] = rssi
                addPeripheral(peripheral: peripheral)
            })
            .store(in: &cancellables)
        
        
        BLEAdapter.shared.peripheralConnectedEvent
            .sink(receiveValue: {
                [weak self] peripheral in
                guard let self = self else { return }
                
                guard var peripheral = peripheral as PeripheralDisplayData? else {
                    return
                }
                
                print("BLECoordinator new peripheral connected: \(peripheral)")
                //                self.handlePeripheralConnected(peripheral)
                
                guard let rssi = self.peripheralRSSIData[peripheral.id] else {
                    return
                }
                peripheral.rssi = rssi
                addPeripheral(peripheral: peripheral)
            })
            .store(in: &cancellables)
        
        BLEAdapter.shared.peripheralDisconnectedEvent
            .sink(receiveValue: {
                [weak self] peripheral in
                guard let self = self else { return }
                
                guard let peripheral = peripheral as PeripheralDisplayData? else {
                    return
                }
                
                print("BLECoordinator peripheral disconnected: \(peripheral)")
                removePeripheral(uuid: peripheral.id)
                
            })
            .store(in: &cancellables)
    }
}
