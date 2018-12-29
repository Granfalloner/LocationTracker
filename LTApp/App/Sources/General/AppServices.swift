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
    fileprivate var reachability: ReachabilityService!
    fileprivate var prefs: PreferencesService!

    // MARK: - Public

    init() {
        location = createLocationService()
        reachability = createReachabilityService()
        prefs = createPreferencesService()
    }
}

// MARK: - ServiceFactory

extension AppServices: ServiceFactory {

    func createLocationService() -> LocationService {
        // Service configuration can be applied here
        return CoreLocationService()
    }

    func createReachabilityService() -> ReachabilityService {
        return SCReachabilityService(with: "www.apple.com")!
    }

    func createPreferencesService() -> PreferencesService {
        return UserDefaultsPreferencesService()
    }
}

// MARK: - Dependency injection

extension LocationServiceClient {
    var location: LocationService {
        return AppServices.shared.location
    }
}

extension ReachabilityServiceClient {
    var reachability: ReachabilityService {
        return AppServices.shared.reachability
    }
}

extension PreferencesServiceClient {
    var prefs: PreferencesService {
        return AppServices.shared.prefs
    }
}
