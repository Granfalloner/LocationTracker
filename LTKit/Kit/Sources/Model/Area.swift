//
//  LocationTypes.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation

public struct Area: Equatable, Hashable {

    // MARK: - Ivars

    public var region: CLCircularRegion
    public var wifi: String?

    // MARK: - Public

    public init(region: CLCircularRegion, wifi: String?) {
        self.region = region
        self.wifi = wifi
    }

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                radius: CLLocationDistance, identifier: String, wifi: String?) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        circularRegion.notifyOnEntry = true
        circularRegion.notifyOnExit = true
        self.init(region: circularRegion, wifi: wifi)
    }
}
