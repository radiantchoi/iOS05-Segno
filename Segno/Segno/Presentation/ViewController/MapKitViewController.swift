//
//  MapKitViewController.swift
//  Segno
//
//  Created by YOONJONG on 2022/11/24.
//

import MapKit
import UIKit

import SnapKit

class MapKitViewController: UIViewController {

    private enum Metric {
        static let topSpace: CGFloat = 30
        static let edgeSpace: CGFloat = 20
        static let mapViewHeight: CGFloat = 500
        static let titleSize: CGFloat = 40
        static let buttonSize: CGFloat = 20
        static let addressSize: CGFloat = 16
    }
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .appFont(.surround, size: Metric.titleSize)
        titleLabel.text = "위치"
        return titleLabel
    }()
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "x.circle"), for: .normal)
        closeButton.tintColor = .appColor(.color4)
        
        var config = UIButton.Configuration.plain()
        let imageConfig = UIImage.SymbolConfiguration(pointSize: Metric.buttonSize)
        config.preferredSymbolConfigurationForImage = imageConfig
        closeButton.configuration = config
        let action = UIAction { _ in
            self.dismiss(animated: true)
        }
        closeButton.addAction(action, for: .touchUpInside)
        return closeButton
    }()
    
    private lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        return mapView
    }()
    
    private lazy var addressLabel: UILabel = {
        let addressLabel = UILabel()
        addressLabel.font = .appFont(.surroundAir, size: Metric.addressSize)
        return addressLabel
    }()
    
    init(location: Location) {
        super.init(nibName: nil, bundle: nil)
        setupMapView(location: location)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupLayout()
    }
    
    private func setupMapView(location: Location) {
        let latitude = location.latitude
        let longitude = location.longitude
        let locationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: locationCoordinate, span: span)
        
        let annotation = MKPointAnnotation()
        annotation.title = "여기지롱"
        annotation.coordinate = locationCoordinate
        mapView.setRegion(region, animated: true)
        mapView.addAnnotation(annotation)
        
        bindLocationItem(location: location)
    }
    
    private func setupLayout() {
        view.addSubviews([titleLabel, closeButton, mapView, addressLabel])
        view.backgroundColor = .appColor(.background)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Metric.topSpace)
            $0.leading.equalToSuperview().inset(Metric.edgeSpace)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.trailing.equalToSuperview().inset(Metric.edgeSpace)
            $0.width.height.equalTo(Metric.buttonSize)
        }
        
        mapView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Metric.edgeSpace)
            $0.leading.trailing.equalToSuperview().inset(Metric.edgeSpace)
            $0.height.equalTo(Metric.mapViewHeight)
        }
        
        addressLabel.snp.makeConstraints {
            $0.top.equalTo(mapView.snp.bottom).offset(Metric.edgeSpace)
            $0.leading.equalToSuperview().inset(Metric.edgeSpace)
        }
    }
    
    private func bindLocationItem(location: Location) {
        // TODO: Location to Address 변환 작업
        addressLabel.text = "경기도 수원시 영통구 덕영대로 1732"
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct MapKitViewController_Preview: PreviewProvider {
    static var previews: some View {
        MapKitViewController(
            location: Location(latitude: 37.248128, longitude: 127.076597)
        )
            .showPreview(.iPhone14Pro)
    }
}
#endif