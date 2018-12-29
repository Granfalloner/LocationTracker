//
//  UserDefaultsPreferenceService.swift
//  LTKit
//
//  Created by Vasyl Myronchuk on 29/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import Foundation

public class UserDefaultsPreferencesService: PreferencesService {

    // MARK: - Ivars

    private let defaults = UserDefaults.standard
    private static let lastWiFiKey = "lastWiFi"

    // MARK: - Public

    public init() {
    }

    // MARK: - PreferencesService

    public var lastWiFi: String? {
        get { return getValue(forKey: UserDefaultsPreferencesService.lastWiFiKey) }
        set { setValue(value: newValue, forKey: UserDefaultsPreferencesService.lastWiFiKey) }
    }
}

// MARK: - Private

private extension UserDefaultsPreferencesService {
    func getValue(forKey key: String) -> Bool {
        return defaults.bool(forKey: key)
    }

    func getValue(forKey key: String) -> Int {
        return defaults.integer(forKey: key)
    }

    func getValue(forKey key: String) -> String? {
        return defaults.string(forKey: key)
    }

    func getValue(forKey key: String) -> Date? {
        return defaults.object(forKey: key) as? Date
    }

    func setValue(value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}
