//
//  MapViewController.swift
//  RxSwiftMapKit
//
//  Created by George Kravas on 18/02/16.
//  Copyright © 2016 George Kravas. All rights reserved.
//

import UIKit
import MapKit
import RxSwift
import RxCocoa

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var disposeBag = DisposeBag()
    var item:MKMapItem!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        mapView.addAnnotation(item.placemark)
        initLocationManager()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initLocationManager() {
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.startMonitoringSignificantLocationChanges()
        locationManager.requestLocation()
    }
    
    func findRoute(location: CLLocation) -> PublishSubject<[MKRoute]> {
        let subject = PublishSubject<[MKRoute]>()
        
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: item.placemark.coordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculateDirectionsWithCompletionHandler { (response, error) -> Void in
            if error != nil {
                subject.onError(error!)
                return
            }
            
            subject.onNext(response!.routes)
            subject.onCompleted()
        }
        
        return subject
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count > 0 {
            findRoute(locations.last!)
                .flatMap({ (routes) -> Observable<[MKPointAnnotation]> in
                    var annotations = [MKPointAnnotation]()
                    for route in routes {
                        self.mapView.addOverlay(route.polyline)
                        self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                        
                        for step in route.steps {
                            let annotation = MKPointAnnotation()
                            annotation.coordinate = step.polyline.coordinate
                            annotation.title = step.description
                            annotations.append(annotation)
                        }
                    }
                    return Observable<[MKPointAnnotation]>.just(annotations)
                })
                .subscribeNext({ (annotations) -> Void in
                    for annotation in annotations {
                        self.mapView.addAnnotation(annotation)
                    }
                })
                .addDisposableTo(disposeBag)
        }
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor()
        return renderer
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error)
    }
}

