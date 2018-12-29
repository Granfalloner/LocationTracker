//
//  AreaAnnotation.swift
//  LocationTracker
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import MapKit
import LTKit

class AreaAnnotation: NSObject {

    // MARK: - Ivars

    let area: Area
    let isActive: Bool

    // MARK: - Public

    init(area: Area, isActive: Bool) {
        self.area = area
        self.isActive = isActive
    }
}

// MARK: - MKAnnotation

extension AreaAnnotation: MKAnnotation {
    var coordinate: CLLocationCoordinate2D {
        return area.region.center
    }

    var title: String? {
        return isActive ? NSLocalizedString("Monitored area", comment: "")
                        : NSLocalizedString("Selected area", comment: "")
    }
}
