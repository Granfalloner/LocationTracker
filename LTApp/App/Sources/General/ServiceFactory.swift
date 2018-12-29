//
//  ServiceFactory.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import LTKit

/// Simple service factory
protocol ServiceFactory {

    func createLocationService() -> LocationService

    func createReachabilityService() -> ReachabilityService

    func createPreferencesService() -> PreferencesService
}
