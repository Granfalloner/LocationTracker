//
//  LocationService.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift

public enum LocationServiceErrors: Error {
    case operationNotPermitted
}

public protocol LocationService {

    // MARK: - Authorization

    var authorizationStatus: Observable<CLAuthorizationStatus> { get }

    func requestAuthorization() // Requests full (always) access

    // MARK: - Monitoring

    var isMonitoringEnabled: Bool { get }

    var maximumMonitoringRadius: CLLocationDistance { get }

    var monitoredRegions: Observable<[CLCircularRegion]> { get }

    func startMonitoring(for region: CLCircularRegion) throws

    func getState(for region: CLCircularRegion) -> Observable<CLRegionState>

    func stopMonitoring(for region: CLCircularRegion)
}
