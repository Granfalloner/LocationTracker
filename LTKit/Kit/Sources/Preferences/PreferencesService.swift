//
//  PreferencesService.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 29/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation

public protocol PreferencesService: AnyObject {

    var lastWiFi: String? { get set }
}
