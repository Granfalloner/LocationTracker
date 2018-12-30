//
//  ViewController.swift
//  LocationTracker
//
//  Created by Vasyl Myronchuk on 27/12/2018.
//  Copyright © 2018 Vasyl Myronchuk. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import RxSwift
import RxCocoa
import LTKit

class MonitoringViewController: UIViewController {

    static let radiusFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    static let coordFromatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 6
        formatter.minimumIntegerDigits = 1
        return formatter
    }()

    // MARK: - Ivars

    @IBOutlet weak var placeholderView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mapView: MKMapView!

    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!

    @IBOutlet weak var radiusLabel: UILabel!
    @IBOutlet weak var minRadiusLabel: UILabel!
    @IBOutlet weak var maxRadiusLabel: UILabel!
    @IBOutlet weak var radiusSlider: UISlider!
    @IBOutlet weak var currentStatusLabel: UILabel!

    @IBOutlet weak var wifiTextField: UITextField!
    @IBOutlet weak var wifiStatusLabel: UILabel!

    @IBOutlet weak var monitoringButton: UIButton!
    @IBOutlet weak var enableLocationButton: UIButton!

    private var viewportAnnotation: AreaAnnotation?
    private var monitoredAnnotation: AreaAnnotation?

    private var presenter: MonitoringPresenterProtocol = MonitoringPresenter()

    private let latitudeVariable = BehaviorSubject<CLLocationDegrees>(value: 0)
    private let longitudeVariable = BehaviorSubject<CLLocationDegrees>(value: 0)

    private let bag = DisposeBag()

    // MARK: - Overrides

    override func viewDidLoad() {
        setupUI()
        bindUI()
        presenter.view = self
        bindPresenter()
    }
}

// MARK: - MonitoringViewProtocol

extension MonitoringViewController: MonitoringViewProtocol {
    var longitude: Observable<CLLocationDegrees> {
        return longitudeVariable
    }

    var latitude: Observable<CLLocationDegrees> {
        return latitudeVariable
    }

    var radius: Observable<CLLocationDistance> {
        return radiusSlider.rx.value.asObservable()
            .map { CLLocationDistance($0) }
    }

    var wifi: Observable<String> {
        return wifiTextField.rx.text.asObservable().map { $0 ?? "" }
    }

    var startMonitoring: Observable<Void> {
        return monitoringButton.rx.tap.asObservable()
    }

    var enableLocation: Observable<Void> {
        return enableLocationButton.rx.tap.asObservable()
    }
}

// MARK: - MKMapViewDelegate

extension MonitoringViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        latitudeVariable.onNext(mapView.centerCoordinate.latitude)
        longitudeVariable.onNext(mapView.centerCoordinate.longitude)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? AreaAnnotation else { return nil }

        let identifier = "AreaAnnotationIdentifier"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKPinAnnotationView

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.pinTintColor = annotation.isActive ? MKPinAnnotationView.greenPinColor()
                                                               : MKPinAnnotationView.redPinColor()
            annotationView?.canShowCallout = true
        } else {
            annotationView?.annotation = annotation
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let areaOverlay = overlay as? AreaOverlay else { return MKOverlayRenderer(overlay: overlay) }

        let circleRenderer = MKCircleRenderer(overlay: areaOverlay)
        circleRenderer.lineWidth = 1.0
        let color = areaOverlay.isActive ? UIColor.green : UIColor.purple
        circleRenderer.strokeColor = color
        circleRenderer.fillColor = color.withAlphaComponent(0.3)
        return circleRenderer
    }
}

// MARK: - Private

private func convertSliderValueToKm(_ value: Float) -> CLLocationDistance {
    return CLLocationDistance(value) / 1000.0
}

private extension MonitoringViewController {
    func setupUI() {
        mapView.delegate = self
        refreshViewportAnnotation()

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
                let currentValue = NSNumber(value: convertSliderValueToKm(Float($0)))
                let stringValue = MonitoringViewController.radiusFormatter.string(from: currentValue)
                return "\(radiusTitle), km: \(stringValue ?? "-")"
            }
            .bind(to: radiusLabel.rx.text)
            .disposed(by: bag)

        Observable.combineLatest(latitude, longitude, radius)
            .subscribe(onNext: { [weak self] _ in
                self?.refreshViewportAnnotation()
            })
            .disposed(by: bag)

        latitudeVariable
            .map { MonitoringViewController.coordFromatter.string(from: NSNumber(value: $0)) }
            .bind(to: latitudeLabel.rx.text)
            .disposed(by: bag)

        longitudeVariable
            .map { MonitoringViewController.coordFromatter.string(from: NSNumber(value: $0)) }
            .bind(to: longitudeLabel.rx.text)
            .disposed(by: bag)
    }

    func bindPresenter() {
        presenter.locationEnabled
            .subscribe(onNext: { [weak self] enabled in
                self?.placeholderView.isHidden = enabled
                self?.contentView.isHidden = !enabled
                self?.mapView.showsUserLocation = enabled
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

        presenter.regionState
            .map { "\(NSLocalizedString("Region status", comment: "")): \($0)" }
            .bind(to: currentStatusLabel.rx.text)
            .disposed(by: bag)

        presenter.wifiState
            .bind(to: wifiStatusLabel.rx.text)
            .disposed(by: bag)

        presenter.monitoredArea
            .subscribe(onNext: { [weak self] area in
                self?.refreshMonitoredAnnotation(for: area)
                self?.wifiTextField.text = area?.wifi
                self?.wifiTextField.sendActions(for: .valueChanged)
            })
            .disposed(by: bag)
    }

    // MARK: - Annotations and overlays

    func addViewportAnnotation() -> AreaAnnotation {
        let name = NSLocalizedString("Monitored area", comment: "")
        let region = CLCircularRegion(center: mapView.centerCoordinate, radius: CLLocationDistance(radiusSlider.value),
                                      identifier: name)
        let annotation = AreaAnnotation(region: region, isActive: false)
        mapView.addAnnotation(annotation)
        return annotation
    }

    func addOverlay(for annotation: AreaAnnotation) {
        let overlay = AreaOverlay(center: annotation.region.center, radius: annotation.region.radius,
                                  isActive: annotation.isActive)
        mapView.addOverlay(overlay)
    }

    func removeOverlay(for annotation: AreaAnnotation) {
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let areaOverlay = overlay as? AreaOverlay else { continue }
            if areaOverlay.isActive == annotation.isActive {
                mapView.removeOverlay(areaOverlay)
                break
            }
        }
    }

    func refreshViewportAnnotation() {
        if let viewportAnnotation = viewportAnnotation {
            removeOverlay(for: viewportAnnotation)
            mapView.removeAnnotation(viewportAnnotation)
        }
        viewportAnnotation = addViewportAnnotation()
        viewportAnnotation.map { addOverlay(for: $0) }
    }

    func refreshMonitoredAnnotation(for area: Area?) {
        if let monitoredAnnotation = monitoredAnnotation {
            removeOverlay(for: monitoredAnnotation)
            mapView.removeAnnotation(monitoredAnnotation)
        }
        if let area = area {
            monitoredAnnotation = AreaAnnotation(region: area.region, isActive: true)
            monitoredAnnotation.map { mapView.addAnnotation($0) }
            monitoredAnnotation.map { addOverlay(for: $0) }
        }
    }
}
