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
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        addNotification()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        requestAccessToCalendar()
    }
    
    func requestAccessToCalendar() {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                DispatchQueue.main.sync(execute: {
                    self.saveCalendar()
                    self.loadEvents()
                })
            }
        })
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
                event.title = ""
                event.calendar = calendar!
                eventController.event = event
                self.present(eventController, animated: true, completion: nil)
            } else {
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
        let eventPredicate = self.eventStore.predicateForEvents(withStart: startDate!, end: endDate!, calendars: [calendar!])
        self.events = self.eventStore.events(matching: eventPredicate).sorted(){
            (e1: EKEvent, e2: EKEvent) -> Bool in
            return e1.startDate.compare(e2.startDate) == ComparisonResult.orderedAscending
        }
        tableView.reloadData()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.storeChanged(_:)), name: NSNotification.Name.EKEventStoreChanged, object: eventStore)
    }
    
    func storeChanged(_ nsNotification: NSNotification) {
         print("Event name \(nsNotification.userInfo?["EKEventStoreChangedObjectIDsUserInfoKey"])")
         self.loadEvents()
    }
    
    func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }
    
}

extension ViewController: EKEventEditViewDelegate {
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CalendarCell
        let event = events[indexPath.row]
        print("Event identifier \(event.eventIdentifier)")
        cell.eventDateLabel.text = getDateFormatter().string(from: event.startDate)
        cell.locationLabel.text = event.location
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = getDeleteAction(indexPath)
        deleteAction.backgroundColor =  UIColor.red
        return [deleteAction]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        eventStore.requestAccess(to: EKEntityType.event, completion: {
            (accessGranted: Bool, error: Error?) in
            if accessGranted == true {
                let eventController = EKEventEditViewController()
                eventController.eventStore = self.eventStore
                eventController.editViewDelegate = self
                eventController.event = self.events[indexPath.row]
                self.present(eventController, animated: true, completion: nil)
            } else {
            }
        })
    }
}

// MARK: - Delete action
extension ViewController {
    
    fileprivate func getDeleteAction(_ indexPath: IndexPath) -> UITableViewRowAction {
        return UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Delete") { (action, indexPath) -> Void in
            self.isEditing = false
            let confirmationAlertController = self.getDeleteController(self.events[indexPath.row])
            confirmationAlertController.addAction(self.getConfirmDeleteAction(self.events[indexPath.row]))
            confirmationAlertController.addAction(self.getCancelDeleteAction(indexPath))
            self.present(confirmationAlertController, animated: true, completion: nil)
        }
    }
    
    fileprivate func getDeleteController(_ event: EKEvent) -> UIAlertController {
        return UIAlertController(title: "Delete", message: "Are you sure want to delete "+event.title+"?", preferredStyle: UIAlertControllerStyle.alert)
    }
    
    fileprivate func getConfirmDeleteAction(_ event: EKEvent) -> UIAlertAction {
        return UIAlertAction(title: "Yes", style: .default, handler: {(alert: UIAlertAction!) -> Void in
            do {
                try self.eventStore.remove(event, span: .thisEvent, commit: true)
               
            } catch {
                print("Error occurred while deleting event " + event.title)
            }
        })
    }
    
    fileprivate func getCancelDeleteAction(_ indexPath: IndexPath) -> UIAlertAction {
        return UIAlertAction(title: "no", style: UIAlertActionStyle.default,handler: {(alert: UIAlertAction!) -> Void in
            self.tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: UITableViewRowAnimation.none)
        })
    }
}

