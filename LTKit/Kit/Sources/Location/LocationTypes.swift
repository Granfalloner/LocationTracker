//
//  LocationTypes.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import CoreLocation

public struct Area: Hashable {
    public var region: CLCircularRegion

    public init(region: CLCircularRegion) {
        self.region = region
    }

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees,
                radius: CLLocationDistance, identifier: String) {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let circularRegion = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        self.init(region: circularRegion)
    }
}
