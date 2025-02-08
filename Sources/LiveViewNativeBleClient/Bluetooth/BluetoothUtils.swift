import CoreBluetooth

enum DataType {
    case uint8, uint16, uint32, int8, int16, int32, float, double, boolean, utf8String, rawData
}

public class BluetoothUtils {

    // Add this helper function to expand short UUIDs
    static func expandShortUUID(_ uuidString: String) -> String {
        if uuidString.count == 4 {
            var expandedUuidString = "0000\(uuidString)-0000-1000-8000-00805F9B34FB".uppercased()
            print("Expanded: uuidString to \(expandedUuidString)")
            return expandedUuidString
        } else {
            return uuidString.uppercased()
        }
    }

    static var uuidMap: [String: (String, DataType)] = [
        // MARK: - Characteristics
        "00002A43-0000-1000-8000-00805F9B34FB": ("alertCategoryId", .uint8), // Alert Category ID
        "00002A06-0000-1000-8000-00805F9B34FB": ("alertLevel", .uint8), // Alert Level
        "00002A3F-0000-1000-8000-00805F9B34FB": ("alertStatus", .uint8), // Alert Status
        "00002AB3-0000-1000-8000-00805F9B34FB": ("altitude", .int32), // Altitude
        "00002A58-0000-1000-8000-00805F9B34FB": ("analog", .rawData), // Analog
        "00002A59-0000-1000-8000-00805F9B34FB": ("analogOutput", .rawData), // Analog output
        "00002A19-0000-1000-8000-00805F9B34FB": ("batteryLevel", .uint8), // Battery Level
        "00002A2B-0000-1000-8000-00805F9B34FB": ("currentTime", .rawData), // Current Time
        "00002A56-0000-1000-8000-00805F9B34FB": ("digital", .rawData), // Digital
        "00002A57-0000-1000-8000-00805F9B34FB": ("digitalOutput", .rawData), // Digital output
        "00002A26-0000-1000-8000-00805F9B34FB": ("firmwareRevisionString", .utf8String), // Firmware Revision String
        "00002A8A-0000-1000-8000-00805F9B34FB": ("firstName", .utf8String), // First Name
        "00002A00-0000-1000-8000-00805F9B34FB": ("deviceName", .utf8String), // Device Name
        "00002A03-0000-1000-8000-00805F9B34FB": ("reconnectionAddress", .rawData), // Reconnection Address
        "00002A05-0000-1000-8000-00805F9B34FB": ("serviceChanged", .rawData), // Service Changed
        "00002A27-0000-1000-8000-00805F9B34FB": ("hardwareRevisionString", .utf8String), // Hardware Revision String
        "00002A6F-0000-1000-8000-00805F9B34FB": ("humidity", .float), // Humidity
        "00002A90-0000-1000-8000-00805F9B34FB": ("lastName", .utf8String), // Last Name
        "00002AAE-0000-1000-8000-00805F9B34FB": ("latitude", .int32), // Latitude
        "00002AAF-0000-1000-8000-00805F9B34FB": ("longitude", .int32), // Longitude
        "00002A29-0000-1000-8000-00805F9B34FB": ("manufacturerNameString", .utf8String), // Manufacturer Name String
        "00002A21-0000-1000-8000-00805F9B34FB": ("measurementInterval", .int32), // Measurement Interval
        "00002A24-0000-1000-8000-00805F9B34FB": ("modelNumberString", .utf8String), // Model Number String
        "00002A6D-0000-1000-8000-00805F9B34FB": ("pressure", .float), // Pressure
        // Thesma breathing pressure
        "61D20A90-71A1-11EA-AB12-0800200C9A66": ("pressure", .float), // Pressure

        "00002A78-0000-1000-8000-00805F9B34FB": ("rainfall", .int32), // Rainfall
        "00002A25-0000-1000-8000-00805F9B34FB": ("serialNumberString", .utf8String), // Serial Number String
        "00002A3B-0000-1000-8000-00805F9B34FB": ("serviceRequired", .boolean), // Service Required
        "00002A28-0000-1000-8000-00805F9B34FB": ("softwareRevisionString", .utf8String), // Software Revision String
        "00002A3D-0000-1000-8000-00805F9B34FB": ("string", .utf8String), // String
        "00002A23-0000-1000-8000-00805F9B34FB": ("systemId", .rawData), // System ID
        "00002A6E-0000-1000-8000-00805F9B34FB": ("temperature", .float), // Temperature
        "00002A1F-0000-1000-8000-00805F9B34FB": ("temperatureCelsius", .float),// Temperature Celsius
        "00002A20-0000-1000-8000-00805F9B34FB": ("temperatureFahrenheit", .float),// Temperature Fahrenheit
        "00002A15-0000-1000-8000-00805F9B34FB": ("timeBroadcast", .rawData), // Time Broadcast
        "00002A37-0000-1000-8000-00805F9B34FB": ("heartRateMeasurement", .rawData), // Heart Rate Measurement
        "00002A5B-0000-1000-8000-00805F9B34FB": ("cscMeasurement", .rawData), // CSC Measurement
        "00002902-0000-1000-8000-00805F9B34FB": ("clientCharacteristicConfig", .rawData), // Client Characteristic Config


        // MARK: - Services
        "00001800-0000-1000-8000-00805F9B34FB": ("genericAccess", .rawData),//Generic Access
        "00001811-0000-1000-8000-00805F9B34FB": ("alertNotificationService",.rawData), // Alert Notification Service
        "00001815-0000-1000-8000-00805F9B34FB": ("automationIO",.rawData),//Automation IO
        "0000180F-0000-1000-8000-00805F9B34FB": ("batteryService", .uint8), // Battery Service
        "0000183B-0000-1000-8000-00805F9B34FB": ("binarySensor",.rawData),//Binary Sensor
        "00001805-0000-1000-8000-00805F9B34FB": ("currentTimeService",.rawData),//Current Time Service
        "0000180A-0000-1000-8000-00805F9B34FB": ("deviceInformation",.utf8String),//Device Information
        "0000183C-0000-1000-8000-00805F9B34FB": ("emergencyConfiguration",.rawData),//Emergency Configuration
        "0000181A-0000-1000-8000-00805F9B34FB": ("environmentalSensing",.rawData),//Environmental Sensing
        "00001801-0000-1000-8000-00805F9B34FB": ("genericAttribute",.rawData),//Generic Attribute
        "00001812-0000-1000-8000-00805F9B34FB": ("humanInterfaceDevice", .rawData),//Human Interface Device
        "00001802-0000-1000-8000-00805F9B34FB": ("immediateAlert",.rawData),//Immediate Alert
        "00001821-0000-1000-8000-00805F9B34FB": ("indoorPositioning", .rawData),//Indoor Positioning
        "00001803-0000-1000-8000-00805F9B34FB": ("linkLoss",.rawData),//Link Loss
        "00001819-0000-1000-8000-00805F9B34FB": ("locationAndNavigation", .rawData),// Location and Navigation
        "00001825-0000-1000-8000-00805F9B34FB": ("objectTransferService", .rawData),//Object Transfer Service
        "00001824-0000-1000-8000-00805F9B34FB": ("transportDiscovery",.rawData), //Transport Discovery
        "00001804-0000-1000-8000-00805F9B34FB": ("txPower", .int8), //Tx Power
        "0000181C-0000-1000-8000-00805F9B34FB": ("userData",.rawData), //User Data


        // BLE Mock service
        "00001523-1212-EFDE-1523-785FEABCD123": ("nordicBlinkyService",.rawData),

        // BLE Mock characteristics
        "00001524-1212-EFDE-1523-785FEABCD123": ("buttonCharacteristic", .uint8),
        "00001525-1212-EFDE-1523-785FEABCD123": ("ledCharacteristic", .uint8),
        "00002A38-0000-1000-8000-00805F9B34FB": ("bodySensorLocation", .uint8)//short UUID mock for body temperature
    ]

    class func name(for uuid: CBUUID) -> String {
        let uuidString = uuid.uuidString
        //print("BluetoothUUID: \(uuidString)")
        let expandedUuidString = expandShortUUID(uuidString)
        return uuidMap[expandedUuidString]?.0 ?? "unknown \(uuid) \(uuidString)"
    }

    class func dataType(for uuid: CBUUID) -> DataType? {
        let uuidString = uuid.uuidString
        let expandedUuidString = expandShortUUID(uuidString)
        return uuidMap[expandedUuidString]?.1
    }


    class var allMappings : [String: (String, DataType)] {
        return uuidMap
    }

    class func isKnown(uuid: CBUUID) -> Bool {
        let uuidString = uuid.uuidString
        let expandedUuidString = expandShortUUID(uuidString)
        return uuidMap[expandedUuidString] != nil
    }

    class func decodeHeartRate(data: Data) -> String? {
        print("Heartrate data count: \(data.count)")
        guard data.count > 0 else {
            print("Data is too short to read heartrate (no flags)")
            return nil
        }

        let flags = data[0]
        let heartRateFormatBit = flags & 0x01

        if heartRateFormatBit == 0 { // uint8 format
            guard data.count >= 2 else {
                print("Data is too short for uint8 heartrate (flags present, but no value)")
                return nil
            }
            let heartRateValue = data[1] // Extract uint8
            print("Decoded uint8 heartrate: \(heartRateValue)")
            return String(describing: heartRateValue)
        } else { // uint16 format
            guard data.count >= 3 else {
                print("Data is too short for uint16 heartrate (flags set, but no 16-bit value)")
                return nil
            }
            let heartRateValue: UInt16? = data.subdata(in: 1..<3).uint16Value // Attempt to extract UInt16
            if let heartRateValue = heartRateValue {
                print("Decoded uint16 heartrate: \(heartRateValue)")
                return String(describing: heartRateValue)
            } else {
                print("Failed to extract uint16 value")
                return nil
            }
        }
    }

    class func decodeValue(for uuid: CBUUID, data: Data) -> Any? {
        let uuidString = uuid.uuidString
        let expandedUuidString = expandShortUUID(uuidString)
        guard let dataType = dataType(for: uuid) else {
            print("Unknown data type for UUID: \(uuid)")
            return nil
        }

        switch dataType {
        case .uint8:
            return data.uint8Value
        case .uint16:
            return data.uint16Value
        case .uint32:
            return data.uint32Value
        case .int8:
            return data.int8Value
        case .int16:
            return data.int16Value
        case .int32:
            return data.int32Value
        case .float:
            return data.floatValue
        case .double:
            return data.doubleValue
        case .boolean:
            return data.booleanValue
        case .utf8String:
            return data.utf8StringValue
        case .rawData:
            return data // Return the raw Data
        }
    }


    static func printCharacteristicProperties(characteristic: CBCharacteristic, peripheral: CBPeripheral) {
        let properties = characteristic.properties

        if properties.contains(.broadcast) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: broadcast")
        }
        if properties.contains(.read) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: read")
        }
        if properties.contains(.writeWithoutResponse) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: writeWithoutResponse")
        }
        if properties.contains(.write) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: write")
        }
        if properties.contains(.notify) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: notify")
        }
        if properties.contains(.indicate) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: indicate")
        }
        if properties.contains(.authenticatedSignedWrites) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: authenticatedSignedWrites")
        }
        if properties.contains(.extendedProperties) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: extendedProperties")
        }
        if properties.contains(.notifyEncryptionRequired) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: notifyEncryptionRequired")
        }
        if properties.contains(.indicateEncryptionRequired) {
            print("\(peripheral.name ?? "Unnamed Peripheral") characteristic \(characteristic.uuid) \(BluetoothUtils.name(for: characteristic.uuid)) has property: indicateEncryptionRequired")
        }
    }
}


extension Data {
    var uint8Value: UInt8? {
        guard count == 1 else { return nil }
        return self[0]
    }

    var uint16Value: UInt16? {
        guard count == 2 else { return nil }
        return UInt16(littleEndian: self.withUnsafeBytes { $0.load(as: UInt16.self) })
    }

    var uint32Value: UInt32? {
        guard count == 4 else { return nil }
        return UInt32(littleEndian: self.withUnsafeBytes { $0.load(as: UInt32.self) })
    }

    var int8Value: Int8? {
        guard count == 1 else { return nil }
        return Int8(self[0])
    }

    var int16Value: Int16? {
        guard count == 2 else { return nil }
        return Int16(littleEndian: self.withUnsafeBytes { $0.load(as: Int16.self) })
    }

    var int32Value: Int32? {
        guard count == 4 else { return nil }
        return Int32(littleEndian: self.withUnsafeBytes { $0.load(as: Int32.self) })
    }

    var floatValue: Float? {
        guard count == 4 else { return nil }
        return self.withUnsafeBytes { buffer in
            #if targetEnvironment(simulator)
                let rawValue = buffer.load(as: Float32.self)
                return Float(rawValue)
            #else
                let swappedValue = CFConvertFloat32HostToSwapped(buffer.load(as: Float32.self))
                let rawValue = CFConvertFloatSwappedToHost(swappedValue)
                return Float(rawValue)
            #endif
        }
    }

    var doubleValue: Double? {
        guard count == 8 else { return nil }
        return self.withUnsafeBytes { buffer in
            #if targetEnvironment(simulator)
                let rawValue = buffer.load(as: Float64.self)
                return Double(rawValue)
            #else
                let swappedValue = CFConvertDoubleHostToSwapped(buffer.load(as: Float64.self))
                let rawValue = CFConvertDoubleSwappedToHost(swappedValue)
                return Double(rawValue)
            #endif
        }
    }

    var booleanValue: Bool? {
        guard count == 1 else { return nil }
        return self[0] != 0
    }

    var utf8StringValue: String? {
        return String(data: self, encoding: .utf8)
    }
}
