//
//  MonitoringSceneProtocols.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation
import RxSwift
import LTKit

protocol MonitoringViewProtocol: AnyObject {

    var longitude: Observable<CLLocationDegrees> { get }
    var latitude: Observable<CLLocationDegrees> { get }

    var radius: Observable<CLLocationDistance> { get }
    var wifi: Observable<String> { get }

    var startMonitoring: Observable<Void> { get }
    var enableLocation: Observable<Void> { get }
}

protocol MonitoringPresenterProtocol {

    var locationEnabled: Observable<Bool> { get }
    var enableLocationTitle: Observable<String> { get }

    var monitoringActive: Observable<Bool> { get }
    var monitoredArea: Observable<Area?> { get }

    var regionState: Observable<String> { get }
    var wifiState: Observable<String> { get }

    var maxRadius: CLLocationDistance { get }

    var view: MonitoringViewProtocol? { get set }
}
