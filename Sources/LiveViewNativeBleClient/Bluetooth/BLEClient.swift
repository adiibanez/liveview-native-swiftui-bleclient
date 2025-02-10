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
    
    @LiveElementIgnored
    var bleAdapter = BLEAdapter()
    
    @LiveElementIgnored
    var jsonEncoder = JSONEncoder()
    
    
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-scan-devices"))
    private var scanForPeripherals: Bool = false
    
    @State private var isConnecting = false
    
    var body: some View {
            Text("Hello")
            //$liveElement.children()
            /*VStack() {
                
                List {
                    Text("List of devices ...")
                    ForEach(coordinator.peripheralDisplayData) { peripheral in
                        Text("Peripheral: \(peripheral.name), RSSI: \(peripheral.rssi)")
                        
                        /*NavigationLink {
                         CharacteristicsView(peripheral: discoveredPeripherals(peripheralId: peripheral.id)!, coordinator: coordinator, isConnecting: $isConnecting) // Navigate to CharacteristicsView
                         } label: {
                         Text("Peripheral: \(peripheral.name), RSSI: \(peripheral.rssi), Status: \(peripheralStateString(state: peripheral.state))")
                         }*/
                    }
                }
                
            }*/
        // remote changes
        //.onChange(of: scanForPeripherals) {
        .onReceive(Just(scanForPeripherals)) { scanForPeripherals in
            if scanForPeripherals == true {
                print("scanForPeripherals true ")
                //coordinator.startScan()
            }
            
            if scanForPeripherals == false {
                print("scanForPeripherals false ")
                //coordinator.stopScan()
            }
        }
        
        .onReceive(bleAdapter.scanStateChangedEvent) { state in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-scan-state-changed",
                    value: ["state": state],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(bleAdapter.centralStateChangedEvent) { state in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-central-state-changed",
                    value: ["state": state],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(bleAdapter.peripheralDiscoveredEvent) {(peripheral, rssi) in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-peripheral-discovered",
                    value: ["peripheral": try jsonEncoder.encode(peripheral)],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(bleAdapter.peripheralConnectedEvent) {
            peripheral in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-peripheral-connected",
                    value: ["peripheral": try jsonEncoder.encode(peripheral)],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onReceive(bleAdapter.serviceDiscoveredEvent) {
            service in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-service-discovered",
                    value: ["service": try jsonEncoder.encode(service)],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        
        .onReceive(bleAdapter.characteristicDiscoveredEvent) {
            characteristic in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-characteristic-discovered",
                    value: ["characteristic": try jsonEncoder.encode(characteristic)],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        //.onChange(of: bleAdapter.characteristicValueChanged) {
        .onReceive(bleAdapter.characteristicValueChangedEvent) {
            characteristicValueUpdate in
            Task {
                
                print("BLECLient onChange: characteristicValueChanged \(characteristicValueUpdate)")
                
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-characteristic-value-changed",
                    value: ["update": try jsonEncoder.encode(characteristicValueUpdate)],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onTapGesture {
            print("TapGesture: Start scan ... ")
           bleAdapter.startScan()
            
            Task {try await $liveElement.context.coordinator.pushEvent(
                type: "click",
                event: "test-event",
                value: ["onTapGesture": true],
                target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
            )
            }
        }.onLongPressGesture {
            print("LongPressGesture: Stop scan ... ")
            bleAdapter.stopScan()
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "test-event",
                    value: ["onLongPressGestrue": true],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }/*.onReceive($liveElement.context.coordinator.receiveEvent("ble_command")) { (payload: [String: Any]) in
            print("Testlitest payload: \(payload)")
        }*/
        
        // setup
        .task {
            
        }
    }
    
}
