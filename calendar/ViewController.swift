//
//  ViewController.swift
//  calendar
//
//  Created by Madasamy Sankarapandian on 01/12/2016.
//  Copyright © 2016 mCruncher. All rights reserved.
//

import UIKit
import EventKit
import EventKitUI

/**
 * Calender interaction https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/EventKitProgGuide/Introduction/Introduction.html
 * Registering for Notifications https://developer.apple.com/library/content/documentation/DataManagement/Conceptual/EventKitProgGuide/ObservingChanges/ObservingChanges.html#//apple_ref/doc/uid/TP40009765-CH4-SW1
 */
class ViewController: UITableViewController {
    
    let eventStore = EKEventStore()
    let userDefaults = UserDefaults.standard
    var events = [EKEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAccessToCalendar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadEvents()
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.storeChanged(_:)), name: NSNotification.Name.EKEventStoreChanged, object: eventStore)
    }
    
    func storeChanged(_ nsNotification: NSNotification) {
        print("Method invoked")
        print("Event name \(nsNotification)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func  saveCalendar() {
        let calender = EKCalendar(for: .event, eventStore: eventStore)
        calender.title = "Furiend"
        calender.source = eventStore.defaultCalendarForNewEvents.source
        do {
            let calendarIdentifier = userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
            if calendarIdentifier == nil  {
                try eventStore.saveCalendar(calender, commit: true)
                userDefaults.set(calender.calendarIdentifier, forKey: "EventTrackerPrimaryCalendar")
                userDefaults.synchronize()
            }
        } catch  {
            print("Error occurred while creating calendar ")
        }
    }
    
    @IBAction func addNewEvent(_ sender: Any) {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                let eventController = EKEventEditViewController()
                let calenderIdentifier = self.userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
                let calendar = self.eventStore.calendar(withIdentifier: calenderIdentifier!)
                eventController.eventStore = self.eventStore
                eventController.editViewDelegate = self
                let event = EKEvent(eventStore: self.eventStore)
                event.title = "Foo"
                event.calendar = calendar!
                eventController.event = event
                self.present(eventController, animated: true, completion: nil)
            } else {
            }
        })
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    self.saveCalendar()
                })
            } else {
                DispatchQueue.main.async(execute: {
                })
            }
        })
    }
    
    func loadEvents() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        // Create start and end date NSDate instances to build a predicate for which events to select
        let startDate = dateFormatter.date(from: "2016-01-01")
        let endDate = dateFormatter.date(from: "2016-12-31")
        let calenderIdentifier = self.userDefaults.string(forKey: "EventTrackerPrimaryCalendar")
        let calendar = self.eventStore.calendar(withIdentifier: calenderIdentifier!)
        let eventPredicate = eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: [calendar!])
        events = eventStore.events(matching: eventPredicate).sorted(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
        }
        for event in events {
            print(event.title)
            print(event.calendar.title)
            print(event.notes ?? "")
            print(event.startDate)
        }
    }
    
}

extension ViewController: EKEventEditViewDelegate {
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = events[indexPath.row].title
        cell.detailTextLabel?.text = String(describing: events[indexPath.row].startDate)
        return cell
    }
}

