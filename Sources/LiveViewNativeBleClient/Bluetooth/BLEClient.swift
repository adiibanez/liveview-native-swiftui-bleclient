import SwiftUI
import Foundation
import Combine
import LiveViewNative
import CoreBluetooth
import LiveViewNativeCore
import LiveViewNativeCoreFFI

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
    @StateObject private var coordinator = BLEClientCoordinator()
    
    @_documentation(visibility: public)
    @LiveAttribute(.init(name: "phx-scan-devices"))
    private var scanForPeripherals: Bool = false
    
    @State private var isConnecting = false
    
    var body: some View {
        NavigationView { // Added NavigationView
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
            .navigationTitle("Discovered Devices") // Added navigation title
        }
        // remote changes
        //.onChange(of: scanForPeripherals) {
        .onReceive(Just(scanForPeripherals)) { scanForPeripherals in
            if scanForPeripherals == true {
                print("scanForPeripherals true ")
                coordinator.startScan()
            }
            
            if scanForPeripherals == false {
                print("scanForPeripherals false ")
                coordinator.stopScan()
            }
        }
        
        .onChange(of: coordinator.scanStateChanged) { state in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-scan-state-changed",
                    value: ["state": state],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        
        .onChange(of: coordinator.centralStateChanged) { state in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-central-state-changed",
                    value: ["state": state],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        /*.onChange(of: coordinator.peripheralDiscovered) {peripheral in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-peripheral-discovered",
                    value: ["peripheral": peripheral.toJSONString()],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onChange(of: coordinator.peripheralConnected) {
            peripheral in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-peripheral-connected",
                    value: ["peripheral": peripheral.toJSONString()],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onChange(of: coordinator.serviceDiscovered) {
            service in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-service-discovered",
                    value: ["service": service.toJSONString()],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        
        .onChange(of: coordinator.characteristicDiscovered) {
            characteristic in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-characteristic-discovered",
                    value: ["characteristic": characteristic.toJSONString()],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        .onChange(of: coordinator.characteristicValueChanged) {
            characteristicValueUpdate in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-characteristic-value-changed",
                    value: ["update": characteristicValueUpdate.toJSONString()],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        */
        
        
        //.onChange(of: coordinator.centralManager.isScanning) {
        .onChange(of: coordinator.bleManager.isScanning) { isScanning in
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "test-event",
                    value: ["is_scanning": isScanning],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }.onTapGesture {
            print("TapGesture: Start scan ... ")
            coordinator.startScan()
            
            Task {try await $liveElement.context.coordinator.pushEvent(
                type: "click",
                event: "test-event2",
                value: ["onTapGesture": true],
                target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
            )
            }
        }.onLongPressGesture {
            print("LongPressGesture: Stop scan ... ")
            coordinator.stopScan()
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "test-event2",
                    value: ["onLongPressGestrue": true],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }.onReceive($liveElement.context.coordinator.receiveEvent("ble_command")) { (payload: [String: Any]) in
            print("Testlitest payload: \(payload)")
        }
        
        // setup
        .task {
            
        }
        .task{
            
        }
    }
    
}
