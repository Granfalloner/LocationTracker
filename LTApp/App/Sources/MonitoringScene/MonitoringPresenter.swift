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

    weak var view: MonitoringViewProtocol?
}

extension MonitoringPresenter: MonitoringPresenterProtocol {
    var locationEnabled: Observable<Bool> {
        return location.authorizationStatus.map { $0 == .authorizedAlways }
    }

    var maxRadius: CLLocationDistance {
        return location.maximumMonitoringRadius
    }
}
