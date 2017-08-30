//
//  MapViewController.swift
//  PlayLocationService
//
//  Created by Wismin Effendi on 8/19/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import os.log
import ToDoCoreDataCloudKit
import ChameleonFramework

protocol TaskLocationDelegate {
    var locationIdenfifier: String { get set }
    var taskLocation: TaskLocation { get set }
}

class MapViewController: UIViewController {

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchText: UITextField!

    var managedContext: NSManagedObjectContext!
    var delegate: TaskLocationDelegate?
    var matchingItems: [MKMapItem] = [MKMapItem]()
        
    let locationManager = CLLocationManager()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.showsUserLocation = true
        mapView.delegate = self
        setUpLocationManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func textFieldReturn(_ sender: UITextField) {
        _ = sender.resignFirstResponder()
        mapView.removeAnnotations(mapView.annotations)
        self.performSearch()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    private func setUpLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 500
        locationManager.requestLocation()
    }
    
}

// MARK: - Search TextField
extension MapViewController {
    
    func performSearch() {
        matchingItems.removeAll()
        let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = searchText.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start {[weak self] (response, error) in
            guard let strongSelf = self else { return }
            if error != nil {
                print("Error occured in search: \(error!.localizedDescription)")
            } else if response!.mapItems.count == 0 {
                print("No matches found")
            } else {
                print("Matches found")
                let number = response!.mapItems.count
                let title: String!
                if number == 1 {
                    title = "\(number) location found"
                } else {
                    title = "\(number) locations found"
                }
                strongSelf.showAlert(title: title, message: "")
                
                for item in response!.mapItems {
                    print("Name = \(item.name)")
                    print("Phone = \(item.phoneNumber)")
                    print("Address = \(item.placemark)")
                    
                    strongSelf.matchingItems.append(item as MKMapItem)
                    print("Matching items = \(strongSelf.matchingItems.count)")
                    
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = item.placemark.coordinate
                    annotation.title = item.name
                    annotation.subtitle = item.placemark.title
                    strongSelf.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default, handler: nil)
        alertController.addAction(dismissAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - MKMapViewDelegate 
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pin"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            if annotation.title! == "My Location" {
                view.pinTintColor = UIColor.flatGreen()
            }
            view.canShowCallout = true
            view.animatesDrop = true
            view.rightCalloutAccessoryView = UIButton.init(type: .detailDisclosure) as UIView
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let taskLocation = TaskLocation(mapAnnotation: view.annotation!)
        showOptionToChoose(taskLocation: taskLocation)
    }
    
    func showOptionToChoose(taskLocation: TaskLocation) {
        let alertController = UIAlertController(title: "Choose Location", message: "Choose this location?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) {[unowned self] (action) in
            taskLocation.title = alertController.textFields![0].text
            self.delegate?.taskLocation = taskLocation
            let identifier = UUID().uuidString
            self.delegate?.locationIdenfifier = identifier
            self.saveToCoreData(identifier: identifier, taskLocation: taskLocation)
            print("We have selected this location: \(taskLocation.coordinate)")
        }
        alertController.addTextField { (textField) in
            textField.text = taskLocation.title
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveToCoreData(identifier: String, taskLocation: TaskLocation) {
        let locationAnnotation = LocationAnnotation(context: managedContext)
        locationAnnotation.setDefaultsForLocalCreate()
        locationAnnotation.title = taskLocation.title!
        locationAnnotation.annotation = taskLocation
        locationAnnotation.identifier = identifier
        
        do {
            try managedContext.save()
        } catch {
            fatalError("Failed to save managedObject: \(error.localizedDescription)")
        }
    }
}


// MARK: - LocationManager Delegate 
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        os_log("Error getting user location: %@", error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            fatalError("We should have one location but we didn't have one")
        }
        let locationCoordinate = location.coordinate
        currentLocationCoordinate = locationCoordinate
        print("Current location: ", locationCoordinate.latitude, locationCoordinate.longitude)
        let region = makeRegion(center: locationCoordinate)
        mapView.region = region
    }
    
    // MARK: - Local Search helper
    private func makeRegion(center: CLLocationCoordinate2D, milesRadius: Double = 10) -> MKCoordinateRegion {
        let distanceInMeter: Double = 2.0 * milesRadius * 1609.344
        let region = MKCoordinateRegionMakeWithDistance(center, distanceInMeter, distanceInMeter)
        return region
    }

}

