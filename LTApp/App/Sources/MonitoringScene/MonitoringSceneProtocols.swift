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

protocol MonitoringViewProtocol: AnyObject {
    var longitude: Observable<CLLocationDegrees> { get }
    var latitude: Observable<CLLocationDegrees> { get }

    var radius: Observable<CLLocationDistance> { get }

    var startMonitoring: Observable<Void> { get }
}

protocol MonitoringPresenterProtocol {

    var locationEnabled: Observable<Bool> { get }
    var maxRadius: CLLocationDistance { get }

    var view: MonitoringViewProtocol? { get set }
}
