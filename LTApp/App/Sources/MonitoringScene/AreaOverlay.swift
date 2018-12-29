//
//  AreaOverlay.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import MapKit

class AreaOverlay: MKCircle {

    // MARK: - Ivars

    private(set) var isActive = false

    // MARK: - Overrides

    convenience init(center coord: CLLocationCoordinate2D, radius: CLLocationDistance, isActive: Bool) {
        self.init(center: coord, radius: radius)
        self.isActive = isActive
    }
}
