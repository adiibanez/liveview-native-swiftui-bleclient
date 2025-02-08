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
          VStack() {
            Text("Hello BLE")
                List {
                   Text("List of devices ...")
                       ForEach(coordinator.peripheralDisplayData) { peripheral in
                           Text("Peripheral: \(peripheral.name), RSSI: \(peripheral.rssi), Status: \(peripheralStateString(state: peripheral.state))")
                           
                           /*NavigationLink {
                               CharacteristicsView(peripheral: discoveredPeripherals(peripheralId: peripheral.id)!, coordinator: coordinator, isConnecting: $isConnecting) // Navigate to CharacteristicsView
                           } label: {
                               Text("Peripheral: \(peripheral.name), RSSI: \(peripheral.rssi), Status: \(peripheralStateString(state: peripheral.state))")
                            }*/
                        }
                    }
                $liveElement.children()
              }
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
        
        //.onChange(of: coordinator.dataUpdate) {
        .onReceive(Just(coordinator.dataUpdate)) { dataUpdate in
            
            print("Data update: " + dataUpdate)
            Task {
                try await $liveElement.context.coordinator.pushEvent(
                    type: "click",
                    event: "ble-response",
                    value: ["response": dataUpdate],
                    target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
                )
            }
        }
        
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
            coordinator.bleManager.scanForPeripherals()
            
            Task {try await $liveElement.context.coordinator.pushEvent(
                type: "click",
                event: "test-event2",
                value: ["onTapGesture": true],
                target: $liveElement.element.attributeValue(for: "phx-target").flatMap(Int.init)
            )
            }
        }.onLongPressGesture {
            print("LongPressGesture: Stop scan ... ")
            coordinator.bleManager.stopScan()
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
            //coordinator.bleManager.delegate = coordinator
            coordinator.bleManager.stopScan()
        }
        .task{
           coordinator.updatePeripheralDisplayData()
        }
    }
    
   func discoveredPeripherals(peripheralId: UUID) -> CBPeripheral?{
        return coordinator.discoveredPeripherals[peripheralId]
    }
    
    func peripheralStateString(state: CBPeripheralState) -> String {
           switch state {
           case .disconnected:
              return "Disconnected"
           case .disconnecting:
               return "Disconnecting"
           case .connected:
               return "Connected"
           case .connecting:
               return "Connecting"
           default:
               return "..."
           }
       }
}
