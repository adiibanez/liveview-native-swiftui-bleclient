import SwiftUI
import Foundation
import Combine
import LiveViewNative
import CoreBluetooth
import LiveViewNativeCore

/// A native Bluetooth Low Energy client view. It can be rendered in a LiveViewNative app using the `BLEClient` element.
///
/// ## Attributes
///  * ``scanForPeripherals``
///  * ``stopScan``
///
@_documentation(visibility: public)
@LiveElement
struct BLEClient<Root: RootRegistry>: View {
    
    @LiveElementIgnored
    @StateObject private var coordinator = BLECoordinator()
    //@ObservedObject  private var coordinator:BLECoordinator
    
    //@LiveElementIgnored
    //var bleAdapter = BLEAdapter()
    
    @LiveElementIgnored
    var jsonEncoder = JSONEncoder()
    
    @LiveElementIgnored
    private var cancellables: Set<AnyCancellable> = []
    
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-scan-devices"))
    private var scanForPeripherals: Bool = false
    
    @State private var isConnecting = false
    
    var body: some View {
        buildMainView
            .onReceive(BLEAdapter.shared.scanStateChangedEvent) { state in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-scan-state-changed",
                        value: state,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            .onReceive(BLEAdapter.shared.centralStateChangedEvent) { state in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-central-state-changed",
                        value: state,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            .onReceive(BLEAdapter.shared.peripheralDiscoveredEvent) {(peripheral, rssi) in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-peripheral-discovered",
                        value: peripheral,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            .onReceive(BLEAdapter.shared.peripheralConnectedEvent) {
                peripheral in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-peripheral-connected",
                        value: peripheral,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            .onReceive(BLEAdapter.shared.serviceDiscoveredEvent) {
                service in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-service-discovered",
                        value: service,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            
            .onReceive(BLEAdapter.shared.characteristicDiscoveredEvent) {
                characteristic in
                Task {
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-characteristic-discovered",
                        value: characteristic,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }
            //.onChange(of: BLEAdapter.shared.characteristicValueChanged) {
            .onReceive(BLEAdapter.shared.characteristicValueChangedEvent) {
                characteristicValueUpdate in
                Task {
                    
                    print("BLECLient onChange: characteristicValueChanged \(characteristicValueUpdate)")
                    
                    try await $liveElement.context.coordinator.pushEvent(
                        type: "click",
                        event: "ble-characteristic-value-changed",
                        value: characteristicValueUpdate,
                        target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                    )
                }
            }

        
        
        
        peripheralList
    }
}

extension BLEClient {
    private var buildMainView: some View {
        VStack() {
            Text("isScanning: \(coordinator.isScannning), Central state: \(coordinator.bleState) Scan state: \(coordinator.isScannning)")
            
            if !coordinator.isScannning {
                
                Button("Scan for devices") {
                    BLEAdapter.shared.startScan()
                }.disabled(coordinator.isScannning)
                //.disabled(coordinator.isScanning)
            } else {
                Button("Stop scan") {
                    BLEAdapter.shared.stopScan()
                }.disabled(!coordinator.isScannning)
                //.disabled(coordinator.isScanning)
            }
        }/*.onChange(of: coordinator.knownPeripherals) {
          newValue in
          print("New value \(newValue)")
          }*/
    }
    
    private var peripheralList: some View {
        List {
            ForEach(coordinator.peripheralDisplayData.sorted(by: { $0.key < $1.key }), id: \.key) { (id, peripheral) in
                HStack {
                    Text(peripheral.name)
                    Text("RSSI: \(peripheral.rssi)")
                    
                    switch peripheral.state {
                    case .connected:
                        Button("Disconnect") {
                            BLEAdapter.shared.disconnect(peripheral_uuid: peripheral.id)
                        }
                    case .disconnected:
                        Button("Connect") {
                            BLEAdapter.shared.connect(peripheral_uuid: peripheral.id)
                        }
                        
                    default:
                        Text("State: \(peripheral.state)")
                    }
                }
            }
        }
        
    }
}
