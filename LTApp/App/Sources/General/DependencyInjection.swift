//
//  DependencyInjection.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 28/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation
import LTKit

// Very simple explicit dependency injection scheme based on protocol conformances.
// Just conform to protocol, and dependency will be injected automatically

// MARK: - LocationServiceClient

protocol LocationServiceClient {
    var location: LocationService { get }
}
