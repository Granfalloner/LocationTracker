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

class MonitoringPresenter: LocationServiceClient {

    static let defaultRegionId = "defaultRegionId"

    // MARK: - Ivars

    weak var view: MonitoringViewProtocol? {
        didSet { setup() }
    }

    private var area = Observable<Area>.never()

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
        return location.monitoredAreas
            .map { $0.contains(where: { $0.region.identifier == MonitoringPresenter.defaultRegionId }) }
    }

    var monitoringState: Observable<String> {
        return area
            .debug("[Premon]")
            .flatMapFirst { [location] in location.getState(for: $0) }
            .map { state in
                switch state {
                case .unknown: return NSLocalizedString("Unknown", comment: "")
                case .inside: return NSLocalizedString("Inside", comment: "")
                case .outside: return NSLocalizedString("Outside", comment: "")
                }
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

        area = Observable.combineLatest(view.latitude,
                                        view.longitude,
                                        view.radius) { (latitude, longitude, radius) in
                Area(latitude: latitude, longitude: longitude, radius: radius,
                                identifier: MonitoringPresenter.defaultRegionId)
            }
            .share(replay: 1)

        view.startMonitoring
            .withLatestFrom(area)
            .subscribe(onNext: { [weak self] area in
                try? self?.location.startMonitoring(for: area)
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
