//
//  coreDataHandler.swift
//  repslymotion
//
//  Created by Darko Dujmovic on 05/06/2017.
//  Copyright © 2017 Repsly. All rights reserved.
//

import UIKit
import CoreData

class coreDataHandler: NSObject {
    
    func getContextt () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func getCurrentDate()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMddHHmm"
        let timeStamp = dateFormatter.string(from: Date())
        //let today = DateFormatter.dateFormat(fromTemplate: "YYYYMMdd", options: 0, locale: nil)
        //let todayDate = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        
        return timeStamp
    }
    
    func saveLogData (logObject:LogObject, completion:(Bool)->()){
        //let date = Date()
        let context = getContextt()
        let entity = NSEntityDescription.entity(forEntityName: "LogData", in: context)
        
        let rawData = NSManagedObject(entity: entity!, insertInto: context)
        rawData.setValue(logObject.accuracy, forKey: "accuracy")
        rawData.setValue(logObject.cmClassification, forKey: "classification")
        rawData.setValue(logObject.currentMileage, forKey: "currMileage")
        rawData.setValue(logObject.lat, forKey: "lat")
        rawData.setValue(logObject.long, forKey: "lon")
        rawData.setValue(logObject.timeStamp, forKey: "timeStamp")
        
        do{
            try context.save()
            print("Saved data")
            completion(true)
            
        }catch let error as NSError {
            print("Error while saving file, \n ****** \(error) \n ***** \(error.userInfo)")
            completion(false)
        }
        
    }
    
    func loadLogData()->[LogData]{
        let context = getContextt()
        var returnArray = [LogData]()
        
        do {
            let fetchRequest:NSFetchRequest<LogData> = LogData.fetchRequest()
            let fetchedRows = try context.fetch(fetchRequest)
            for row in fetchedRows{
                returnArray.append(row)
            }
            return returnArray
            
        } catch {
            fatalError()
        }
        
        
        return returnArray
    }

}
