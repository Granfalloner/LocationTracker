//
//  AppServices.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import LTKit

class AppServices {

    static var shared = AppServices()

    // MARK: - Ivars

    fileprivate var location: LocationService!

    // MARK: - Public

    init() {
        location = createLocationService()
    }
}

// MARK: - ServiceFactory

extension AppServices: ServiceFactory {

    func createLocationService() -> LocationService {
        // Service configuration can be applied here
        return CoreLocationService()
    }
}

// MARK: - Dependency injection

extension LocationServiceClient {
    var location: LocationService {
        return AppServices.shared.location
    }
}
