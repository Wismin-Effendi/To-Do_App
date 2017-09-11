//
//  TaskLocation.swift
//  PlayLocationService
//
//  Created by Wismin Effendi on 8/20/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import Foundation
import MapKit
import os.log

public class TaskLocation: NSObject, NSCoding, MKAnnotation {
    public var title: String?
    public let subtitle: String?
    public let coordinate: CLLocationCoordinate2D
    
    
    public init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        os_log("We create a Task Location %@", log: .default, type: .debug, coordinate as CVarArg)
    }
    
    public init(mapAnnotation: MKAnnotation) {
        self.title = mapAnnotation.title!
        self.subtitle = mapAnnotation.subtitle!
        self.coordinate = mapAnnotation.coordinate
    }
    
    public convenience override init() {
        self.init(title: "", subtitle: "", coordinate: CLLocationCoordinate2D())
    }
    
    // MARK: - NSCoding protocol
    // So that we could save this object as transformable in Core Data
    public required init?(coder aDecoder: NSCoder) {
        title = aDecoder.decodeObject(forKey: "title") as? String
        subtitle = aDecoder.decodeObject(forKey: "subtitle") as? String
        let latitude = aDecoder.decodeObject(forKey: "latitude") as! CLLocationDegrees
        let longitude = aDecoder.decodeObject(forKey: "longitude") as! CLLocationDegrees
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(subtitle, forKey: "subtitle")
        aCoder.encode(coordinate.latitude as NSNumber, forKey: "latitude")
        aCoder.encode(coordinate.longitude as NSNumber, forKey: "longitude")
    }
}
