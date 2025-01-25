//
//  UIApplication+.swift
//  OllamaChat
//
//  Created by Roger on 2025/1/25.
//  Copyright © 2025 IdeasForm. All rights reserved.
//

import Network
import SystemConfiguration
import UIKit


enum CurrentOS {
    case iOS
    case macOS
    
    static var current: CurrentOS {
#if os(macOS)
        return .macOS
#else
        return .iOS
#endif
    }
    
    static var isiOS: Bool {
        return CurrentOS.current == .iOS
    }
    
    static var ismacOS: Bool {
        return CurrentOS.current == .macOS
    }
}

struct NetworkAddresses {
    let ipv4: String?
    let ipv6: String?
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func getNetworkAddresses() -> NetworkAddresses {
        var ipv4Address: String?
        var ipv6Address: String?
        
        // Get list of all interfaces on the local machine
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return NetworkAddresses(ipv4: nil, ipv6: nil)
        }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            let interface = ptr?.pointee
            
            // Check interface name first
            let name = String(cString: (interface?.ifa_name)!)
            if name == "en0" { // WiFi interface
                let family = interface?.ifa_addr.pointee.sa_family
                
                // Convert interface address to a string
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface?.ifa_addr,
                           socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                           &hostname,
                           socklen_t(hostname.count),
                           nil,
                           0,
                           NI_NUMERICHOST)
                
                let address = String(cString: hostname)
                
                // Categorize address by family
                if family == UInt8(AF_INET) {
                    ipv4Address = address
                } else if family == UInt8(AF_INET6) {
                    ipv6Address = address
                }
            }
        }
        
        return NetworkAddresses(ipv4: ipv4Address, ipv6: ipv6Address)
    }
}
