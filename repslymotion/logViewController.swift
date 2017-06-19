//
//  logViewController.swift
//  repslymotion
//
//  Created by Darko Dujmovic on 05/06/2017.
//  Copyright © 2017 Repsly. All rights reserved.
//

import UIKit

class logViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var cdh = coreDataHandler()
    var logData = [LogData](){
        didSet{
            logData.reverse()
        }
    }
    
    
    
    @IBOutlet weak var detailLogTV: UITableView!
    //var logObjects
    
    @IBAction func closeLog(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        logData = cdh.loadLogData()
        detailLogTV.delegate = self
        // Do any additional setup after loading the view.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logData.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = detailLogTV.dequeueReusableCell(withIdentifier: "cell") //as! detailLogTableViewCell
        let timestamp = logData[indexPath.row].timeStamp ?? "No timestamp"
        let classification = logData[indexPath.row].classification ?? "No classification"
        let mileage = logData[indexPath.row].currMileage
        
        cell!.textLabel?.text = ("\(String(describing: timestamp)) - \(String(describing: classification)) -  \(String(format:"%.2f", mileage)) m")
        return cell!
    }

    
}
