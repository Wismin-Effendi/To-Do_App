//
//  MapViewController.swift
//  PlayLocationService
//
//  Created by Wismin Effendi on 8/19/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import MapKit
import os.log
import ToDoCoreDataCloudKit

protocol TaskLocationDelegate {
    var location: LocationAnnotation? { get set }
}

class MapViewController: UIViewController {

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchText: UITextField!

    var managedContext: NSManagedObjectContext!
    var delegate: TaskLocationDelegate?
    var matchingItems: [MKMapItem] = [MKMapItem]()
        
    let locationManager = CLLocationManager()
    var currentLocationCoordinate: CLLocationCoordinate2D?
    
    var locationAnnotation: LocationAnnotation!
    
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
                os_log("Error occured in search: %@", log: .default, type: OSLogType.error, (error?.localizedDescription)!)
            } else if response!.mapItems.count == 0 {
                os_log("No matches found", log: .default, type: .debug)
            } else {
                os_log("Matches found", log: .default, type: .debug)
                let number = response!.mapItems.count
                let title: String!
                if number == 1 {
                    title = "\(number) \(NSLocalizedString("location found", comment:""))"
                } else {
                    title = "\(number) \(NSLocalizedString("locations found", comment:""))"
                }
                strongSelf.showAlert(title: title, message: "")
                
                for item in response!.mapItems {
                    strongSelf.matchingItems.append(item as MKMapItem)
                    os_log("Matching items = %@", log: .default, type: .debug, strongSelf.matchingItems.count)
                    
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
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .default, handler: nil)
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
        let alertController = UIAlertController(title: NSLocalizedString("Choose Location", comment:"Alert title"), message: NSLocalizedString("Choose this location?", comment:""), preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel",comment:"Cancel button"), style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment:"OK button"), style: .default) {[unowned self] (action) in
            taskLocation.title = alertController.textFields![0].text
            let identifier = UUID().uuidString
            self.saveToCoreData(identifier: identifier, taskLocation: taskLocation)
            self.delegate?.location = self.locationAnnotation
            os_log("We have selected this location: %@", log: .default, type: .debug, taskLocation.coordinate as CVarArg)
        }
        alertController.addTextField { (textField) in
            textField.text = taskLocation.title
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveToCoreData(identifier: String, taskLocation: TaskLocation) {
        locationAnnotation = LocationAnnotation(context: managedContext)
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
        os_log("Error getting user location: %@", log: .default, type: .error, error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            fatalError("We should have one location but we didn't have one")
        }
        let locationCoordinate = location.coordinate
        currentLocationCoordinate = locationCoordinate
        os_log("Current location: %@ %@", log: .default, type: .debug, locationCoordinate.latitude, locationCoordinate.longitude)
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

