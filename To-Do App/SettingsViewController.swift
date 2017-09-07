//
//  SettingsViewController.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/2/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import LicensesKit

class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var dueHourFromNowLabel: UILabel!
    @IBOutlet weak var dueHourFromNowStepper: UIStepper!
    @IBOutlet weak var archivePastCompletionSwitch: UISwitch!
    @IBOutlet weak var deleteUnusedArchivedLocationsSwitch: UISwitch!
    @IBOutlet weak var showLicenseButton: UIButton!
    
    let userDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        tableView.separatorStyle = .none
    }
    
    private func configureUI() {
        configureDueHourStepper()
        configureArchivePastCompletionSwitch()
        configureDeleteUnusedArchiveLocationSwitch()
        configureShowLicenseButton()
    }
    
    private func configureShowLicenseButton() {
        showLicenseButton.tintColor = UIColor.flatSkyBlue()
        showLicenseButton.backgroundColor = UIColor.clear
    }
    
    private func configureArchivePastCompletionSwitch() {
        let switchValue = userDefaults.bool(forKey: UserDefaults.Keys.archivePastCompletion)
        archivePastCompletionSwitch.isOn = switchValue
        archivePastCompletionSwitch.tintColor = UIColor.flatSkyBlue()
        archivePastCompletionSwitch.onTintColor = UIColor.flatSkyBlue()
    }
    
    private func configureDeleteUnusedArchiveLocationSwitch() {
        let switchValue = userDefaults.bool(forKey: UserDefaults.Keys.deleteUnusedArchivedLocations)
        deleteUnusedArchivedLocationsSwitch.isOn = switchValue
        deleteUnusedArchivedLocationsSwitch.tintColor = UIColor.flatSkyBlue()
        deleteUnusedArchivedLocationsSwitch.onTintColor = UIColor.flatSkyBlue()
    }

    private func configureDueHourStepper() {
        dueHourFromNowStepper.isContinuous = false
        dueHourFromNowStepper.autorepeat = true
        dueHourFromNowStepper.minimumValue = 0
        dueHourFromNowStepper.maximumValue = 24
        let hours:Double = userDefaults.double(forKey: UserDefaults.Keys.dueHoursFromNow)
        dueHourFromNowStepper.value = hours
        dueHourFromNowLabel.text = String(hours)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dueHourStepperChanged(_ sender: UIStepper) {
        dueHourFromNowLabel.text = String(dueHourFromNowStepper.value)
        userDefaults.set(dueHourFromNowStepper.value, forKey: UserDefaults.Keys.dueHoursFromNow)
    }
    
    @IBAction func archivePastCompletedTasksChanged(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: UserDefaults.Keys.archivePastCompletion)
    }
    
    @IBAction func deleteUnusedArchivedLocations(_ sender: UISwitch) {
        userDefaults.set(sender.isOn, forKey: UserDefaults.Keys.deleteUnusedArchivedLocations)
    }

    @IBAction func showLicences(_ sender: Any) {
        let licensesViewController = LicensesViewController()
        licensesViewController.setNoticesFromJSONFile(filepath: Bundle.main.path(forResource: "licenses", ofType: "json")!)
        licensesViewController.pageHeader = "<center><h2> Third Party Code and Icons Used in this Application</h2></center>"
        let navCont = UINavigationController(rootViewController: licensesViewController)
        licensesViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped(_:)))
        present(navCont, animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 4
        case 1: return 1
        default: return 0
        }
    }
}
