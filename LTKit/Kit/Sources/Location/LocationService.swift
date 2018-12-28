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

    var monitoredAreas: Observable<[Area]> { get }

    func startMonitoring(for area: Area) throws

    func getState(for area: Area) -> Observable<CLRegionState>

    func stopMonitoring(for area: Area)
}
