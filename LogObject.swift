//
//  LogObject.swift
//  repslymotion
//
//  Created by Darko Dujmovic on 01.06.2017..
//  Copyright © 2017. Repsly. All rights reserved.
//

import Foundation

class LogObject: NSObject {
    let timeStamp:String
    let cmClassification:String
    let long:Double
    let lat:Double
    let currentMileage:Double
    let accuracy:Double
    
    init(timeStamp:String, cmClassification:String, long:Double, lat:Double, currentMileage:Double, accuracy:Double){
        self.timeStamp = timeStamp
        self.cmClassification = cmClassification
        self.long = long
        self.lat = lat
        self.currentMileage = currentMileage
        self.accuracy = accuracy
    }
}
