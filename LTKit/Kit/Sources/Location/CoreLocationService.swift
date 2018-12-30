//
//  CoreLocationService.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift

public class CoreLocationService: NSObject {

    // MARK: - Ivars

    private let locationManager: CLLocationManager

    private let authorizationStatusVariable = BehaviorSubject<CLAuthorizationStatus>(value: .notDetermined)
    private let monitoredRegionsVariable = BehaviorSubject<[CLCircularRegion]>(value: [])

    private var regionToObservablesMap = [String: BehaviorSubject<CLRegionState>]()

    // MARK: - Overrides

    public override init() {
        locationManager = CLLocationManager()
        super.init()
        fetchMonitoredRegions()
        locationManager.delegate = self
    }
}

// MARK: - LocationService

extension CoreLocationService: LocationService {

    // MARK: - Authorization

    public var authorizationStatus: Observable<CLAuthorizationStatus> {
        return authorizationStatusVariable
    }

    public func requestAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .denied, .restricted:
            break
        case .notDetermined, .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        }
    }

    // MARK: - Monitoring

    public var isMonitoringEnabled: Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }

    public var maximumMonitoringRadius: CLLocationDistance {
        return locationManager.maximumRegionMonitoringDistance
    }

    public var monitoredRegions: Observable<[CLCircularRegion]> {
        return monitoredRegionsVariable
    }

    public func startMonitoring(for region: CLCircularRegion) throws {
        guard isMonitoringEnabled else { throw LocationServiceErrors.operationNotPermitted }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            locationManager.startMonitoring(for: region)
        default:
            throw LocationServiceErrors.operationNotPermitted
        }
    }

    public func getState(for region: CLCircularRegion) -> Observable<CLRegionState> {
        guard let observable = regionToObservablesMap[region.identifier] else {
            let newObservable = BehaviorSubject<CLRegionState>(value: .unknown)
            regionToObservablesMap[region.identifier] = newObservable
            locationManager.requestState(for: region)
            return newObservable
        }
        locationManager.requestState(for: region)
        return observable
    }

    public func stopMonitoring(for region: CLCircularRegion) {
        locationManager.stopMonitoring(for: region)
    }
}

// MARK: - CLLocationManagerDelegate

extension CoreLocationService: CLLocationManagerDelegate {

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatusVariable.onNext(status)
    }

    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }
        do {
            var curValue = try monitoredRegionsVariable.value()
            if let index = curValue.firstIndex(where: { $0.identifier == circularRegion.identifier }) {
                curValue[index] = circularRegion
                monitoredRegionsVariable.onNext(curValue)
            } else {
                monitoredRegionsVariable.onNext(curValue + [circularRegion])
            }
        } catch {
            /// - ToDo: error logging
        }
    }

    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // ...
    }

    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // ...
    }

    public func locationManager(_ manager: CLLocationManager,
                                didDetermineState state: CLRegionState, for region: CLRegion) {
        regionToObservablesMap[region.identifier]?.onNext(state)
    }

    public func locationManager(_ manager: CLLocationManager,
                                monitoringDidFailFor region: CLRegion?, withError error: Error) {
//        guard let region = region else { return }
//        regionToObservablesMap[region.identifier]?.onError(error)
    }
}

// MARK: - Private

private extension CoreLocationService {
    func fetchMonitoredRegions() {
        let regions = locationManager.monitoredRegions
            .compactMap { $0 as? CLCircularRegion }
        monitoredRegionsVariable.onNext(regions)
    }
}
