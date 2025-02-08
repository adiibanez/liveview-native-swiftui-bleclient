import LiveViewNative
import LiveViewNativeStylesheet
import SwiftUI

public extension Addons {
    /// An alias for the ``BLE`` addon, with proper capitalization when using it as a type.
    typealias BLE = Ble
    
    /// The main LiveView Native registry for the LiveViewNativeBLE add-on library.
    #if swift(>=5.8)
    @_documentation(visibility: public)
    #endif
    @Addon
    public struct Ble<Root: RootRegistry> {
        public enum TagName: String {
            case bleClient = "BLEClient"
        }
        
        public static func lookup(_ name: TagName, element: ElementNode) -> some View {
            switch name {
            case .bleClient:
                BLEClient<Root>()
            }
        }
    }
}
