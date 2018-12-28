//
//  ViewController.swift
//  LocationTracker
//
//  Created by Vasyl Myronchuk on 27/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift
import RxCocoa

class MonitoringViewController: UIViewController {

    static let radiusFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    // MARK: - Ivars

    @IBOutlet weak var placeholderView: UIView!
    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!

    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var minRadiusLabel: UILabel!
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var currentStatusLabel: UILabel!

    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var monitoringButton: UIButton!
    @IBOutlet weak var enableLocationButton: UIButton!

    var presenter: MonitoringPresenterProtocol = MonitoringPresenter()
    let bag = DisposeBag()

    // MARK: - Overrides

    override func viewDidLoad() {
        setupUI()
        presenter.view = self
        bindUI()
    }
}

// MARK: - MonitoringViewProtocol

extension MonitoringViewController: MonitoringViewProtocol {
    var longitude: Observable<CLLocationDegrees> {
        return longitudeTextField.rx.text.asObservable()
            .debug("[Long]")
            .map { $0.flatMap { CLLocationDegrees($0) } ?? 0 }
            .debug("[LongConv]")
    }

    var latitude: Observable<CLLocationDegrees> {
        return latitudeTextField.rx.text.asObservable()
            .map { $0.flatMap { CLLocationDegrees($0) } ?? 0 }
    }

    var radius: Observable<CLLocationDistance> {
        return radiusSlider.rx.value.asObservable()
            .map { convertSliderValueToKm($0) }
    }

    var startMonitoring: Observable<Void> {
        return monitoringButton.rx.tap.asObservable()
    }

    var enableLocation: Observable<Void> {
        return enableLocationButton.rx.tap.asObservable()
    }
}

// MARK: - Private

private func convertSliderValueToKm(_ value: Float) -> CLLocationDistance {
    return CLLocationDistance(value) / 1000.0
}

private extension MonitoringViewController {
    func setupUI() {
        radiusSlider.minimumValue = 100 // 100 meters is recommended
        radiusSlider.maximumValue = Float(presenter.maxRadius)

        let minValue = NSNumber(value: convertSliderValueToKm(radiusSlider.minimumValue))
        let maxValue = NSNumber(value: convertSliderValueToKm(radiusSlider.maximumValue))
        minRadiusLabel.text = MonitoringViewController.radiusFormatter.string(from: minValue)
        maxRadiusLabel.text = MonitoringViewController.radiusFormatter.string(from: maxValue)
    }

    func bindUI() {
        let radiusTitle = NSLocalizedString("Radius", comment: "")
        radius
            .map {
                let stringValue = MonitoringViewController.radiusFormatter.string(from: NSNumber(value: $0))
                return "\(radiusTitle), km: \(stringValue ?? "-")"
            }
            .bind(to: radiusLabel.rx.text)
            .disposed(by: bag)

        presenter.locationEnabled
            .subscribe(onNext: { [weak self] enabled in
                self?.placeholderView.isHidden = enabled
                self?.contentView.isHidden = !enabled
            })
            .disposed(by: bag)

        presenter.enableLocationTitle
            .bind(to: enableLocationButton.rx.title())
            .disposed(by: bag)

        presenter.monitoringActive
            .map { $0 ? NSLocalizedString("Update monitoring", comment: "")
                      : NSLocalizedString("Start monitoring", comment: "") }
            .bind(to: monitoringButton.rx.title())
            .disposed(by: bag)

        presenter.monitoringState
            .map { "\(NSLocalizedString("Current status", comment: "")): \($0)" }
            .bind(to: currentStatusLabel.rx.text)
            .disposed(by: bag)
    }
}
