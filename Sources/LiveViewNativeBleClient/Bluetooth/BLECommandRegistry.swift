import CoreBluetooth
import CoreBluetoothMock
import CoreLocation
import Foundation

struct BLECommand {
    let name: String  // Command identifier (e.g., "start_scan", "connect")
    let parameters: [String: Any]  // Command-specific parameters
}

protocol CommandRegistry {
    func register(
        commandName: String, action: @escaping ([String: Any]) -> Void)
    func execute(command: BLECommand)
}

class BLECommandRegistry: CommandRegistry {
    private var commands: [String: ([String: Any]) -> Void] = [:]
    private var registeredPeripherals: [String: CBMPeripheralSpec] = [:]

    func register(
        commandName: String, action: @escaping ([String: Any]) -> Void
    ) {
        commands[commandName] = action
    }

    func execute(command: BLECommand) {
        guard let action = commands[command.name] else {
            print(
                "Error: Command '\(command.name)' not found in real command registry."
            )
            return
        }
        action(command.parameters)
    }

    func parseBLECommand(payload: [String: Any]) -> BLECommand? {
        guard let commandName = payload["command"] as? String else {
            print("Error: Missing 'command' key in payload.")
            return nil
        }

        // Extract parameters (handle potential type mismatches if needed)
        let parameters = payload["parameters"] as? [String: Any] ?? [:]

        return BLECommand(name: commandName, parameters: parameters)
    }

    static func castParamsToType<T: Decodable>(
        _ parameters: [String: Any], castTo type: T.Type
    ) throws -> T? {
        do {

            let jsonData = try JSONSerialization.data(
                withJSONObject: parameters)

            // Decode data to struct
            let result = try JSONDecoder().decode(type, from: jsonData)
            return result
        } catch {
            print("Failed to decode parameters: \(error)")
            return nil
        }
    }

    func registerMockCommands(
        blinky: CBMPeripheralSpec, hrm: CBMPeripheralSpec,
        thingy: CBMPeripheralSpec, powerPack: CBMPeripheralSpec,
        hrmHeartrateCharacteristic: CBMCharacteristicMock
    ) {

        register(commandName: "simulateProximityChange") { parameters in

            var params: ProximityChangePayload? = nil

            //Use do catch to identify posible errors
            do {
                params = try BLECommandRegistry.castParamsToType(
                    parameters, castTo: ProximityChangePayload.self)
            } catch {
                print("Error: \(error)")
            }

            //After check and asign values for the new call, unwrap it
            if let params = params {
                let peripheralId = params.peripheralId
                let proximityString = params.proximity
                let proximity = self.mapProximity(proximityString)

                guard let peripheral = self.getTargetPeripheral(peripheralId)
                else {
                    print(
                        "Peripheral not found to update proximity for \(peripheralId) to \(proximityString)"
                    )
                    return
                }

                peripheral.simulateProximityChange(proximity)
                print(
                    "Simulated proximity change for \(peripheralId) to \(proximityString)"
                )
            }

        }
    }

    private func mapProximity(_ proximityString: String) -> CBMProximity {
        switch proximityString {
        case "immediate": return .immediate
        case "near": return .near
        case "far": return .far
        case "outOfRange": return .outOfRange
        default:
            print("Wrong type set .Unknown")
            return .immediate
        }
    }

    func registerPeripheral(peripheral: CBMPeripheralSpec) {
        registeredPeripherals[peripheral.identifier.uuidString] = peripheral
    }

    private func getTargetPeripheral(_ peripheralId: String)
        -> CBMPeripheralSpec?
    {

        guard let peripheral = registeredPeripherals[peripheralId] else {
            print("No peripherals available with that ID \(peripheralId)")
            return nil
        }

        return peripheral
    }
}

// Example payload for simulating a proximity change
struct ProximityChangePayload: Decodable {
    let peripheralId: String
    let proximity: String  // "immediate", "near", "far"
}

// Example payload for simulating a value update
struct ValueUpdatePayload: Decodable {
    let peripheralId: String
    let characteristicUuid: String
    let value: String  //Base64 representation?
}
