//
//  TaskLocation.swift
//  PlayLocationService
//
//  Created by Wismin Effendi on 8/20/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import Foundation
import MapKit

class TaskLocation: NSObject, NSCoding, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
    
    init(mapAnnotation: MKAnnotation) {
        self.title = mapAnnotation.title!
        self.subtitle = mapAnnotation.subtitle!
        self.coordinate = mapAnnotation.coordinate
    }
    
    convenience override init() {
        self.init(title: "", subtitle: "", coordinate: CLLocationCoordinate2D())
    }
    
    // MARK: - NSCoding protocol
    // So that we could save this object as transformable in Core Data
    required init?(coder aDecoder: NSCoder) {
        title = aDecoder.decodeObject(forKey: "title") as? String
        subtitle = aDecoder.decodeObject(forKey: "subtitle") as! String
        let latitude = aDecoder.decodeObject(forKey: "latitude") as! CLLocationDegrees
        let longitude = aDecoder.decodeObject(forKey: "longitude") as! CLLocationDegrees
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(with aCoder: NSCoder) {
        print("Try to save the following to core data: Title: \(title),  Lat: \(coordinate.latitude),  Lon: \(coordinate.longitude)")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(subtitle, forKey: "subtitle")
        aCoder.encode(coordinate.latitude as NSNumber, forKey: "latitude")
        aCoder.encode(coordinate.longitude as NSNumber, forKey: "longitude")
    }
    
    
}
