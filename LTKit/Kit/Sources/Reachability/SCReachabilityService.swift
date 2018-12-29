//
//  SCReachabilityService.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 29/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import RxSwift

public class SCReachabilityService: ReachabilityService {

    // MARK: - Ivars

    public let host: String
    public private(set) var isMonitoring = false

    private let queue = DispatchQueue(label: "com.locationtracker.reachabilityservice")
    private let reachability: SCNetworkReachability
    private let reachabilityStateVariable = BehaviorSubject<ReachabilityState>(value: .notReachable)

    // MARK: - ReachabilityService

    public required init?(with host: String) {
        self.host = host
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
        self.reachability = reachability
    }

    public var state: Observable<ReachabilityState> {
        return reachabilityStateVariable
    }

    public func startMonitoring() throws {
        guard !isMonitoring else { return }
        defer { isMonitoring = true }

        var context = SCNetworkReachabilityContext(version: 0, info: nil,
                                                   retain: nil, release: nil, copyDescription: nil)
        context.info = Unmanaged.passUnretained(self).toOpaque()

        let callback: SCNetworkReachabilityCallBack? = {
            (reachability: SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) in
            guard let info = info else { return }

            let unmanagedSelf = Unmanaged<SCReachabilityService>.fromOpaque(info).takeUnretainedValue()

            DispatchQueue.main.async {
                unmanagedSelf.updateState(with: flags)
            }
        }

        if !SCNetworkReachabilitySetCallback(reachability, callback, &context) {
            throw ReachabilityServiceErrors.cannotStartService
        }

        if !SCNetworkReachabilitySetDispatchQueue(reachability, queue) {
            throw ReachabilityServiceErrors.cannotStartService
        }

        queue.async {
            var flags = SCNetworkReachabilityFlags()
            SCNetworkReachabilityGetFlags(self.reachability, &flags)
            self.updateState(with: flags)
        }
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        defer { isMonitoring = false }

        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
}

// MARK: - Private

private extension SCReachabilityService {
    func updateState(with flags: SCNetworkReachabilityFlags) {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)

        guard isReachable && (!needsConnection || canConnectWithoutUserInteraction) else {
            reachabilityStateVariable.onNext(.notReachable)
            return
        }

        if flags.contains(.isWWAN) {
            reachabilityStateVariable.onNext(.cellular)
        } else {
            reachabilityStateVariable.onNext(.wifi(getWiFiName()))
        }
    }

    func getWiFiName() -> String? {
        guard let interface = CNCopySupportedInterfaces() else { return nil }

        for index in 0..<CFArrayGetCount(interface) {
            let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interface, index)
            let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
            if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString),
                let interfaceData = unsafeInterfaceData as? [String: AnyObject] {
                return interfaceData["SSID"] as? String
            }
        }

        return nil
    }
}
