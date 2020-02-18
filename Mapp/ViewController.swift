//
//  ViewController.swift
//  Mapp
//
//  Created by Fernando Limón Flores on 28/01/20.
//  Copyright © 2020 Fernando Limón Flores. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters: Double = 100000
    var previousLocation: CLLocation?
    let geoCoder = CLGeocoder()
    var directionsArray: [MKDirections] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        checkLocationServices()
    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation(){
        if let location = locationManager.location?.coordinate{
            let region = MKCoordinateRegion.init(center:location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationServices(){
        
        if CLLocationManager.locationServicesEnabled() {
            //Set location manager
            setupLocationManager()
            checkLocationAuthorization()
            
        }else{
            //Show alert letting the user they have to turn this on.
        }
    }
    
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus(){
            
        case .authorizedWhenInUse:
            //Do map stuff
            startTRackingUserLocation()
            break
        case .denied:
            //Show alert with instructions to turn on location
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //Show alert to let them know what´s up
            break
        case .authorizedAlways:
            break
            
        }
    }
    
    func startTRackingUserLocation(){
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation{
        
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            //TODO: Inform user we don't have their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [unowned self] (response, error) in
            //TODO: Handle error if needed
            guard let response = response else { return } //TODO: Show response not available in an alert
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let startingLocation            = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: startingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel()}
        directionsArray.removeAll()
    }

    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
    
}

extension ViewController: CLLocationManagerDelegate{
    
    /*func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
        
    }*/
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
        
    }
    
}

extension ViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        
        guard let previousLocation = self.previousLocation else {return}
        
        guard center.distance(from: previousLocation) > 50 else {return}
        
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center){[weak self] (placemark, error) in guard let self = self else {return}
            
            if let _ = error{
                //Show alert informing the user
                return
            }
            
            guard let placemark = placemark?.first else {
                //Show alert informing the user
                return
            }
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.addressLabel.text = "\(streetName) \(streetNumber)"
                print("\(streetName) \(streetNumber)")
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}
