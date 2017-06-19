//
//  ViewController.swift
//  repslymotion
//
//  Created by Darko Dujmovic on 30/05/2017.
//  Copyright © 2017 Repsly. All rights reserved.
//

import UIKit
import CoreMotion
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var theMap: MKMapView!
    @IBOutlet weak var trackingLabel: UILabel!
    @IBOutlet weak var stepsDistance: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var desiredAccuracyLabel: UILabel!
    @IBOutlet weak var desiredAccuracySlider: UISlider!
    @IBOutlet weak var startEndDayBtn: UIButton!
    @IBOutlet weak var drivingMileage: UILabel!
    @IBOutlet weak var GPSSpeedLabel: UILabel!
    @IBOutlet weak var GPSMileageLabel: UILabel!
    @IBOutlet weak var automotiveButton: UIButton!
    @IBOutlet weak var addStepsBtn: UIButton!
    
    @IBOutlet weak var overrideWalking: UIButton!
    @IBOutlet weak var overrideUnknown: UIButton!
    @IBOutlet weak var overrideAddSteps: UIButton!
    
    //show or hide development buttons
    var isDeployment = true
    
    
    @IBAction func addDistance(_ sender: Any) {
        pDistance += 71
    }
    @IBAction func setWalking(_ sender: Any) {
        currentMotionActivity = .walking
    }
    var didLogInitialState = false
    
    @IBAction func setUnknown(_ sender: Any) {
        currentMotionActivity = .unknown
    }
    let cdh = coreDataHandler()
    
    // MARK : Start end day
    var didStartDay:Bool = false{
        didSet{
            if didStartDay{
            if !didLogInitialState{
                logData()
                didLogInitialState = true
                }
            }else if !didStartDay{
                didLogInitialState = false
            }
        }
    }
    
    @IBAction func startEndDay(_ sender: Any) {
        if !didStartDay {
            startEndDayBtn.setTitle("End day", for: .normal)
            didStartDay = true
            //mockAutomotive = true
            self.startAllSystems()
        }else{
            startEndDayBtn.setTitle("Start day", for: .normal)
            didStartDay = false
            disengageCLUpdates()
            //show session recap
        }
    }
    
    // MARK : Development, mock automotive to start using gps for distance measurement
    @IBAction func toggleAutomotive(_ sender: Any) {
        if didStartDay {
        if mockAutomotive {
            automotiveButton.setTitle("Not automotive", for: .normal)
            mockAutomotive = false
            simulateWalking = true
            disengageCLUpdates()
            
        }
        else{
            automotiveButton.setTitle("Automotive", for: .normal)
            previousLocation = nil
            mockAutomotive = true
            simulateWalking = false
            startAllSystems()
            }
        }
        
    }
    
    var mockAutomotive = true {
        didSet{
            if mockAutomotive {
                previousLocation = nil }
            
        }
    }
 
    
    //MARK
    var simulateWalking = false{
        didSet{
            if simulateWalking{
                if CMPedometer.isStepCountingAvailable(){
                    self.pMeter.startUpdates(from: Date()-1, withHandler: { (data, error) in
                        self.pDistance = data?.distance as! Double //as! Int
                        
                    })
                }
               // didRequestStopCLTracking = false
                
            }else{
//                if CMPedometer.isStepCountingAvailable(){
//                    self.pMeter.startUpdates(from: Date()-1, withHandler: { (data, error) in
//                        //self.pDistance = data?.distance as! Int
//                    })
//                }
                
                if CMPedometer.isStepCountingAvailable(){
                    self.pMeter.stopUpdates()
                }
            
            }
        }
    }
    
    //locations when NOT walking, v2
    var locationsWhenNotWalking = [CLLocation](){
        didSet{
            var prevLoc:CLLocation? = nil
            for location in locationsWhenNotWalking{
             //draw mkployline
                
                let curLoc = location
                if prevLoc != nil {
                //draw
                    coord0 = CLLocationCoordinate2D(latitude: prevLoc!.coordinate.latitude, longitude: prevLoc!.coordinate.longitude)
                    coord1 = CLLocationCoordinate2D(latitude: curLoc.coordinate.latitude, longitude: curLoc.coordinate.longitude)
                    
                    polyline = MKPolyline(coordinates: [coord0!, coord1!], count: 2)
                    theMap.add(polyline!)
                }
                prevLoc = location
            }
        }
        
    }
    
    //locations when walking
    var locationsWhenWalking = [CLLocation](){
        didSet{
            for location in locationsWhenWalking{
                //add pins to map
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                theMap.addAnnotation(annotation)
            }
            didRequestStopCLTracking = true
        }
    }
    
    //when requested, other requests are ignored so the timer is not upset
    var didRequestStopCLTracking = false {
        didSet{
            if !didRequestStopCLTracking{
                self.trackingLabel.text = "Using GPS"
                statusView.backgroundColor = UIColor(red:0.36, green:0.75, blue:0.92, alpha:1.0)
                //setPastelView(forView: statusView, greenIsTrue: true)
            }else{
                disengageCLUpdates()
                self.trackingLabel.text = "NOT using GPS"
                statusView.backgroundColor = UIColor(red:0.87, green:0.50, blue:0.92, alpha:1.0)
                //setPastelView(forView: statusView, greenIsTrue: false)
            }
        }
    }
    
    //MARK : managers
    let motionManager = CMMotionManager()
    let motionActivityManager = CMMotionActivityManager()
    let clManager = CLLocationManager()
    let pMeter = CMPedometer()
    
    var timer = Timer()
    
    let shutOfCLLocUpdatesTime = 10.0
    var lastLocation:CLLocation?
    
    var isMoving = true {
        didSet{
            if didStartDay{
               // logData()
                
                if isMoving{
                    isInMotion = "In motion"
                }else{
                    isInMotion = "Static"
                }
                
                classificationLabel.text = ("\(String(describing: currentMotionActivity)) - \(String(describing: isInMotion))")
                
                if (isMoving && currentMotionActivity == activityType.automotive) || (isMoving && currentMotionActivity == activityType.unknown)
                   // || currentMotionActivity == activityType.unknown
                {
                timer.invalidate()
                clManager.startUpdatingLocation()
                didRequestStopCLTracking = false
                clManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                }
                else if
                    currentMotionActivity == activityType.walking || (currentMotionActivity == activityType.unknown && !isMoving) || (currentMotionActivity == activityType.automotive && !isMoving)
                {
                    
                timer.invalidate()
                timer = Timer.scheduledTimer(timeInterval: shutOfCLLocUpdatesTime, target: self, selector: #selector(disengageCLUpdates), userInfo: nil, repeats: false)
                }
                
            }
        }
    }
    
    func disengageCLUpdates() {
        
    if !didRequestStopCLTracking {
            
        if currentMotionActivity == activityType.walking {
                locationsWhenWalking.append(currentLocation!)
            }
        didRequestStopCLTracking = true
        clManager.stopUpdatingLocation()
        clManager.stopUpdatingHeading()
        clManager.stopMonitoringVisits()
        clManager.stopMonitoringSignificantLocationChanges()
        theMap.showsUserLocation = false
        print("\n ** Request to stop updates")
        horizontalAccuracy = Int((currentLocation?.horizontalAccuracy)!)
    }
    }
    
    enum activityType {
        case automotive
        case walking
        case running
        case unknown
    }
    
    var isInMotion = "Started"
    var timerForWalking = Timer()
    var currentMotionActivity:activityType = .unknown {
        willSet{
            logData()
            timerForWalking.invalidate()
        }
        didSet{
            classificationLabel.text = ("\(String(describing: currentMotionActivity)) - \(String(describing: isInMotion))")
            
            if currentMotionActivity == activityType.walking {
                
                
                disengageCLUpdates()
                didRequestStopCLTracking = true
                timerForWalking = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(getLocationWithTimeout), userInfo: nil, repeats: true)
//
//
//                if CMPedometer.isStepCountingAvailable(){
//                    self.pMeter.startUpdates(from: Date()-1, withHandler: { (data, error) in
//                        self.pDistance = data?.distance as! Double //as! Int
//                    })
//                }
            }else{
               // self.pMeter.stopUpdates()
                previousLocation = nil
                timerForWalking.invalidate()
                clManager.startUpdatingLocation()
                didRequestStopCLTracking = false
            }
            
        }
    }
    func getLocationWithTimeout(){
        getLocation(withDesiredAccuracy: 50, andTimeout: 7)
    }
    
    var gpsMileage:Double = 0.0 {
        didSet{
            
           // if currentMotionActivity == activityType.automotive || currentMotionActivity == activityType.unknown{
            if currentMotionActivity != activityType.walking {
                drivingMileage.text = ("\(String(format:"%.2f", gpsMileage)) m")
                }
        }
    }
    
    var locaitonsWhenAutomotive = [CLLocation]()
    
    var previousLocation:CLLocation?
    var currentLocation:CLLocation?{
        willSet{
            if currentLocation != nil {
                previousLocation = currentLocation
                if currentMotionActivity == activityType.automotive || currentMotionActivity == activityType.unknown {
                  //  location .append(currentLocation!)
                }
            }
            
        }
        
    }
    
    //accuracy that triggers GPS-OFF when walking triggers GPS-ON
    var desiredAccuracyWhenWalking = 50
    
    var horizontalAccuracy = 0 {
        didSet{
            //when walking triggers core location this is where we disengage it when and if it reaches desired horizontal accuracy
            if horizontalAccuracy <= desiredAccuracyWhenWalking && currentMotionActivity == activityType.walking
            {
                print ("Stop updating")
               // if !didRequestStopCLTracking {
                    disengageCLUpdates()
               // }
            }
        }
    }
    
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
  
    //
    var classificationAndActivity = "Stationary unknown"
    
    
//    var activityClassification:String = "unclassified"{
//        didSet{
//            classificationAndActivity = ("\(activityClassification) - \(currentMotionActivity)")
//            classificationLabel.text = classificationAndActivity
//        }
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //hide development labels

        if !isDeployment {
            overrideUnknown.isHidden = true
            overrideWalking.isHidden = true
            overrideAddSteps.isHidden = true
        }
        
        
        theMap.delegate = self
        trackingLabel.text = "Day not started"
        startEndDayBtn.setTitle("Start day", for: .normal)
        if didStartDay {
            startAllSystems()
        }
        theMap.showsCompass = true
        
        clManager.allowsBackgroundLocationUpdates = true
        clManager.pausesLocationUpdatesAutomatically = false
        
    }
    
    // MARK : Get data from sensors
    func startAllSystems(){
        timer.invalidate()
        
        if CMPedometer.isStepCountingAvailable(){
            self.pMeter.startUpdates(from: Date()-1, withHandler: { (data, error) in
                self.pDistance = data?.distance as! Double //as! Int
            })
        }
        
        motionActivityManager.startActivityUpdates(to: OperationQueue.current!) { (activity) in
            
            // MARK : motion classification
            if (activity?.automotive)! {
                self.currentMotionActivity = activityType.automotive
            }
            if (activity?.walking)!{
                self.currentMotionActivity = activityType.walking
            }
            if (activity?.running)!{
                self.currentMotionActivity = activityType.running
            }
            if (activity?.unknown)!{
                self.currentMotionActivity = activityType.unknown
            }
            
            
            // MARK : return bool
            if (activity?.stationary)!{
                self.isMoving = false
                //self.clManager.stopUpdatingLocation()
                //self.clManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
                // self.clManager.stopUpdatingLocation()
                
            }else{
                self.isMoving = true
                
                // self.clManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
                //self.clManager.startUpdatingLocation()
            }
            
        }
        
        
        
        clManager.delegate = self
        //clManager.activityType = CLActivityType.otherNavigation
        clManager.requestWhenInUseAuthorization()
        clManager.startUpdatingLocation()
        didRequestStopCLTracking = false
        clManager.desiredAccuracy = kCLLocationAccuracyBest
        
     
    
    
    }
    
    // MARK: Location manager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       //if location accuracy correct
        currentLocation = locations[0]
        var span:MKCoordinateSpan = MKCoordinateSpanMake(0.001, 0.001)
        //in meters per second
        if let speed = currentLocation?.speed, speed > 20 {
         span = MKCoordinateSpanMake(0.01, 0.01)
            
        }
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake((currentLocation?.coordinate.latitude)!, (currentLocation?.coordinate.longitude)!)
        let region:MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span)
        theMap.setRegion(region, animated: true)
        horizontalAccuracy = Int((currentLocation?.horizontalAccuracy)!)
        print("Horizontal accuracy \(horizontalAccuracy)")
        self.theMap.showsUserLocation = true
        let distanceBetweenTwoLocations = previousLocation?.distance(from: currentLocation!) ?? 0
        gpsMileage += distanceBetweenTwoLocations
//        if previousLocation != nil{
//        drawMKPolyline()
//        //drawMKPolylineFromArrayOfLocations()
//        }
        
        if currentMotionActivity != activityType.walking{
            locationsWhenNotWalking.append(currentLocation!)
        }
    }
    
    // MARK : Walking location - get location every n meters
    
    var i = 1.0
    var getLocationEvery = 70.00 //meters
    
    var pDistance = 0.0 {
        didSet{
            if didStartDay{
            let dist = ("\(String(format:"%.2f", pDistance)) m")
            stepsDistance.text = "\(dist)"
                
           // if didRequestStopCLTracking{
            let coeficient = pDistance / (i*getLocationEvery)
            print("Coeficient is \(coeficient)")
            if (coeficient >= 1) && currentMotionActivity == activityType.walking
            {
                //get location
                getLocation(withDesiredAccuracy: desiredAccuracyWhenWalking, andTimeout: 10.0)
                didRequestStopCLTracking = false
                i+=1
                }
            }
            
        //    }
        }
    }
    
    func getLocation(withDesiredAccuracy accuracy:Int, andTimeout timeout:Double){
        clManager.startUpdatingLocation()
        didRequestStopCLTracking = false
        //walkingDesiredAccuracy = accuracy
        //safety timeout in case horizontal accuracy never gets to desired value
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(disengageCLUpdates), userInfo: nil, repeats: false)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKPolyline.self){
            let polylineRender = MKPolylineRenderer(polyline: polyline!)
            polylineRender.strokeColor = UIColor.red
            polylineRender.lineWidth = 2.0
            
//            let distanceBetweenTwoLocations = previousLocation?.distance(from: currentLocation!) ?? 0
//            gpsMileage += distanceBetweenTwoLocations
            
            return polylineRender
        }
        
        return MKPolylineRenderer()
    }
    
    var coord0:CLLocationCoordinate2D?
    var coord1:CLLocationCoordinate2D?
    var polyline:MKPolyline?
    
    func drawMKPolyline(){
        if currentMotionActivity == activityType.automotive || currentMotionActivity == activityType.unknown{
            coord0 = (previousLocation?.coordinate)!
            coord1 = (currentLocation?.coordinate)!
            
            polyline = MKPolyline(coordinates: [coord0!, coord1!], count: 2)
            theMap.add(polyline!)
        }
    }
    
//    func drawMKPolylineFromArrayOfLocations(){
//
//
//
//        for automotiveLocation in locaitonsWhenAutomotive {
//
//            coord0 = (previousLocation?.coordinate)!
//            coord1 = (currentLocation?.coordinate)!
//            let previousLocation = automotiveLocation
//
//            polyline = MKPolyline(coordinates: [coord0!, coord1!], count: 2)
//            theMap.add(polyline!)
//
//        }
//        if currentMotionActivity == activityType.automotive || currentMotionActivity == activityType.unknown{
//            coord0 = (previousLocation?.coordinate)!
//            coord1 = (currentLocation?.coordinate)!
//
//            polyline = MKPolyline(coordinates: [coord0!, coord1!], count: 2)
//            theMap.add(polyline!)
//        }
//    }
    
    func logData(){
        
        
        let logClassification:String?
        let currMileageForLog:Double?
        
        
        if currentMotionActivity == activityType.automotive{
            logClassification = "Automotive"
            currMileageForLog = gpsMileage
        }else if currentMotionActivity == activityType.unknown{
            logClassification = "Unclassified"
            currMileageForLog = gpsMileage
        }else if currentMotionActivity == activityType.walking{
            logClassification = "Walking"
            currMileageForLog = pDistance
        }else if currentMotionActivity == activityType.running{
            logClassification = "Running"
            currMileageForLog = pDistance
        }else{
            logClassification = "//"
            currMileageForLog = gpsMileage
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd, HH:mm"
        let timestamp = dateFormatter.string(from: Date())
        
        if currentLocation != nil{
        let logObject = LogObject(timeStamp: String(describing:timestamp),
                                  cmClassification:("\(logClassification!) - \(isInMotion)"),
                                  long: currentLocation!.coordinate.longitude,
                                  lat: currentLocation!.coordinate.latitude,
                                  currentMileage: currMileageForLog!,
                                  accuracy: Double(horizontalAccuracy))
        
        cdh.saveLogData(logObject: logObject) { (success) in
            print("Saved successfully")
        }
        }
        else {
            let logObject = LogObject(timeStamp: String(describing:timestamp),
                                      cmClassification:("Start day - \(logClassification!)"),
                                      long: 0.00,
                                      lat: 0.00,
                                      currentMileage: currMileageForLog!,
                                      accuracy: Double(horizontalAccuracy))
            
            cdh.saveLogData(logObject: logObject) { (success) in
                print("Saved successfully")
                
            }
    }
    
    
    }
//    func setPastelView(forView view:UIView,greenIsTrue:Bool){
//        
//        
//        let pastelView = PastelView(frame: view.bounds)
//        pastelView.startPastelPoint = .bottomLeft
//        pastelView.endPastelPoint = .topRight
//        pastelView.frame.size.width = self.view.bounds.width
//        pastelView.animationDuration = 1.5
//        
//        if greenIsTrue {
//            pastelView.setColors(PastelGradient.ok.colors())}
//        else{
//             pastelView.setColors(PastelGradient.pleaseRefresh.colors())
//        }
//        
//        pastelView.startAnimation()
//        
//        view.insertSubview(pastelView, at: 0)
//        
//    }
}




