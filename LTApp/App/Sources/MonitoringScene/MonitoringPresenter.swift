//
//  MonitoringPresenter.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import LTKit

class MonitoringPresenter: LocationServiceClient, ReachabilityServiceClient, PreferencesServiceClient {

    static let defaultRegionId = "defaultRegionId"
    static let defaultWifi = "Wi-Fi"

    // MARK: - Ivars

    weak var view: MonitoringViewProtocol? {
        didSet { setup() }
    }

    private var area = Observable<Area>.never()
    private var wifi = BehaviorSubject<String>(value: MonitoringPresenter.defaultWifi)

    let bag = DisposeBag()
}

// MARK: - MonitoringPresenterProtocol

extension MonitoringPresenter: MonitoringPresenterProtocol {
    var locationEnabled: Observable<Bool> {
        return location.authorizationStatus.map { $0 == .authorizedAlways }
    }

    var enableLocationTitle: Observable<String> {
        return location.authorizationStatus
            .map { status in
                switch status {
                case .notDetermined: return NSLocalizedString("Enable", comment: "")
                case .authorizedWhenInUse, .denied, .restricted: return NSLocalizedString("Go to Settings", comment: "")
                case .authorizedAlways: return ""
                }
            }
    }

    var monitoringActive: Observable<Bool> {
        return monitoredArea.map { $0 != nil }
    }

    var monitoringState: Observable<String> {
        return monitoredArea
            .flatMapLatest { [location] area -> Observable<CLRegionState?> in
                if let area = area {
                    return location.getState(for: area.region).map { $0 }
                } else {
                    return .just(nil)
                }
            }
            .map { state in
                guard let state = state else { return NSLocalizedString("Not monitoring", comment: "") }
                switch state {
                case .unknown: return NSLocalizedString("Unknown", comment: "")
                case .inside: return NSLocalizedString("Inside", comment: "")
                case .outside: return NSLocalizedString("Outside", comment: "")
                }
            }
    }

    var monitoredArea: Observable<Area?> {
        let monitoredRegion = location.monitoredRegions
            .map { $0.first(where: { $0.identifier == MonitoringPresenter.defaultRegionId }) }

        return Observable.combineLatest(monitoredRegion, wifi) { (region, wifi) -> Area? in
            guard let region = region else { return nil }
            return Area(region: region, wifi: wifi)
        }
    }

    var maxRadius: CLLocationDistance {
        return location.maximumMonitoringRadius
    }
}

// MARK: - Private

private extension MonitoringPresenter {
    func setup() {
        guard let view = view else { return }

        view.enableLocation
            .withLatestFrom(location.authorizationStatus)
            .subscribe(onNext: { [weak self] status in
                self?.handleEnableLocation(status)
            })
            .disposed(by: bag)

        wifi.onNext(prefs.lastWiFi ?? MonitoringPresenter.defaultWifi)

        area = Observable.combineLatest(view.latitude,
                                        view.longitude,
                                        view.radius,
                                        view.wifi) { (latitude, longitude, radius, wifi) in
                Area(latitude: latitude, longitude: longitude, radius: radius,
                     identifier: MonitoringPresenter.defaultRegionId, wifi: wifi)
            }
            .share(replay: 1)

        view.startMonitoring
            .withLatestFrom(area)
            .subscribe(onNext: { [weak self] area in
                self?.prefs.lastWiFi = area.wifi
                self?.wifi.onNext(area.wifi)
                try? self?.location.startMonitoring(for: area.region)
            })
            .disposed(by: bag)

    }

    func handleEnableLocation(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            return
        case .authorizedWhenInUse, .denied, .restricted:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        case .notDetermined:
            location.requestAuthorization()
        }
    }
}
