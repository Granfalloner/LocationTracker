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
    private let monitoredAreasVariable = BehaviorSubject<[Area]>(value: [])

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

    public var monitoredAreas: Observable<[Area]> {
        return monitoredAreasVariable
    }

    public func startMonitoring(for area: Area) throws {
        guard isMonitoringEnabled else { throw LocationServiceErrors.operationNotPermitted }

        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            locationManager.startMonitoring(for: area.region)
        default:
            throw LocationServiceErrors.operationNotPermitted
        }
    }

    public func getState(for area: Area) -> Observable<CLRegionState> {
        guard let observable = regionToObservablesMap[area.region.identifier] else {
            let newObservable = BehaviorSubject<CLRegionState>(value: .unknown)
            regionToObservablesMap[area.region.identifier] = newObservable
            locationManager.requestState(for: area.region)
            return newObservable
        }
        return observable
    }

    public func stopMonitoring(for area: Area) {
        locationManager.stopMonitoring(for: area.region)
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
            var curValue = try monitoredAreasVariable.value()
            if let index = curValue.firstIndex(where: { $0.region.identifier == circularRegion.identifier }) {
                curValue[index] = Area(region: circularRegion)
                monitoredAreasVariable.onNext(curValue)
            } else {
                monitoredAreasVariable.onNext(curValue + [Area(region: circularRegion)])
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
        let areas = locationManager.monitoredRegions
            .compactMap { ($0 as? CLCircularRegion).map { Area(region: $0) } }
        monitoredAreasVariable.onNext(areas)
    }
}
