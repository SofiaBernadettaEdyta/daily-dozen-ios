//
//  MainViewController.swift
//  DailyDozen
//
//  Copyright © 2019 Nutritionfacts.org. All rights reserved.
//
// swiftlint:disable function_body_length

import UIKit
import UserNotifications

class MainViewController: UIViewController {
        
    let mainTabBarController = UITabBarController()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.greenColor
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.isTranslucent = false

        // Global App Settings
        setupUnitsType()
        setupReminders()
        setupTabNaviation()
        
        //UserDefaults.standard.set(false, forKey: SettingsKeys.hasSeenFirstLaunch) // :!!!:DEBUG: default should be true
    }
    
    private func setupUnitsType() {
        // ----- Settings: Units Type -----
        if UserDefaults.standard.bool(forKey: SettingsKeys.hasSeenFirstLaunch) == false {
            // Show UnitsType toggle to be similar to current user's experience
            UserDefaults.standard.set(true, forKey: SettingsKeys.unitsTypeTogglePref)
        }
        
        if UserDefaults.standard.object(forKey: SettingsKeys.unitsTypePref) == nil {
            // Skip if user had already set a preferred imperial or metric choice
            // :NYI:ToBeLocalized: set initial default based on device language
            UserDefaults.standard.set(UnitsType.imperial.rawValue, forKey: SettingsKeys.unitsTypePref)
        }
    }
    
    private func setupReminders() {
        // ----- Settings: Reminders -----
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if UserDefaults.standard.object(forKey: SettingsKeys.reminderCanNotify) == nil {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                UserDefaults.standard.set(settings.authorizationStatus == .authorized, forKey: SettingsKeys.reminderCanNotify)
            }
        }

        if UserDefaults.standard.object(forKey: SettingsKeys.reminderHourPref) == nil {
            UserDefaults.standard.set(8, forKey: SettingsKeys.reminderHourPref)
        }

        if UserDefaults.standard.object(forKey: SettingsKeys.reminderMinutePref) == nil {
            UserDefaults.standard.set(0, forKey: SettingsKeys.reminderMinutePref)
        }

        if UserDefaults.standard.object(forKey: SettingsKeys.reminderSoundPref) == nil {
            UserDefaults.standard.set(true, forKey: SettingsKeys.reminderSoundPref)
        }

        guard UserDefaults.standard.bool(forKey: SettingsKeys.reminderCanNotify) else { return }

        let content = UNMutableNotificationContent()
        content.title = "DailyDozen app." // :NYI:ToBeLocalized:
        content.subtitle = "Do you remember about the app?" // :NYI:ToBeLocalized:
        content.body = "Use this app on a daily basis!" // :NYI:ToBeLocalized:
        content.badge = 1

        if UserDefaults.standard.bool(forKey: SettingsKeys.reminderSoundPref) {
            content.sound = UNNotificationSound.default
        }

        var dateComponents = DateComponents()
        dateComponents.hour = UserDefaults.standard.integer(forKey: SettingsKeys.reminderHourPref)
        dateComponents.minute = UserDefaults.standard.integer(forKey: SettingsKeys.reminderMinutePref)

        let dateTrigget = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "request", content: content, trigger: dateTrigget)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }

    }
    
    private func setupTabNaviation() {
        // ----- Tab Navigation Setup -----
        if UserDefaults.standard.bool(forKey: SettingsKeys.hasSeenFirstLaunch) == false {
            UserDefaults.standard.set(true, forKey: SettingsKeys.show21TweaksPref)
        }
        
        mainTabBarController.tabBar.barTintColor = UIColor.white
        mainTabBarController.tabBar.isTranslucent = false
        mainTabBarController.tabBar.tintColor = UIColor.black
        updateTabBarController()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTabBarController(notification:)),
            name: NSNotification.Name(rawValue: "NoticeUpdatedShowTweaksTab"),
            object: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: - Navigation

    @objc func updateTabBarController(notification: Notification) {
        if let index = notification.object as? Int {
            updateTabBarController(selectedIndex: index)
        } else {
            updateTabBarController()
        }
    }

    func updateTabBarController(selectedIndex: Int? = nil) {
        var controllerArray = [UIViewController]()
        
        // Daily Dozen Tab
        let tabDailyDozenStoryboard = UIStoryboard(name: "ServingsPager", bundle: nil) // :!!!: hard coded storyboard
        guard
            let tabDailyDozenViewController = tabDailyDozenStoryboard
                .instantiateInitialViewController() as? ServingsPagerViewController
            else { fatalError("Did not instantiate `ServingsPagerViewController`") }

        let titleDoze = NSLocalizedString("navtab.doze", comment: "Daily Dozen (proper noun) navigation tab")
        tabDailyDozenViewController.title = titleDoze
        tabDailyDozenViewController.tabBarItem = UITabBarItem.init(
            title: titleDoze, // shows below tab bar item icon
            image: UIImage(named: "ic_tabapp_dailydozen"),
            tag: 0
        )
        controllerArray.append(tabDailyDozenViewController)

        // Tweaks Tab
        if UserDefaults.standard.bool(forKey: SettingsKeys.show21TweaksPref) {
            let tab2ndStoryboard = UIStoryboard(name: "TweaksPager", bundle: nil)  // :!!!: hard coded storyboard
            guard
                let tabTweaksViewController = tab2ndStoryboard
                    .instantiateInitialViewController() as? TweaksPagerViewController
                else { fatalError("Did not instantiate `TweaksPagerViewController`") }

            let titleTweak = NSLocalizedString("navtab.tweaks", comment: "Twenty-One Tweaks (proper noun) navigation tab")
            tabTweaksViewController.title = titleTweak
            tabTweaksViewController.tabBarItem = UITabBarItem.init(
                title: titleTweak,
                image: UIImage(named: "ic_tabapp_21tweaks"),
                tag: 1
            )
            controllerArray.append(tabTweaksViewController)
        }
        
        // More Tab
        let tabInfoStoryboard = UIStoryboard(name: "Menu", bundle: nil) // :!!!: hard coded storyboard
        guard
            let tabInfoViewController = tabInfoStoryboard
                .instantiateInitialViewController() as? MenuTableViewController
            else { fatalError("Did not instantiate More `MenuTableViewController`") }

        let titleInfo = NSLocalizedString("navtab.info", comment: "More Information navigation tab")
        tabInfoViewController.title = titleInfo
        tabInfoViewController.tabBarItem = UITabBarItem.init(
            title: titleInfo,
            image: UIImage(named: "ic_tabapp_more"),
            tag: 0
        )
        controllerArray.append(tabInfoViewController)

        // Settings Tab
        let tabSettingsStoryboard = UIStoryboard(name: "Settings", bundle: nil) // :!!!: hard coded storyboard
        guard
            let tabSettingsViewController = tabSettingsStoryboard
                .instantiateInitialViewController() as? SettingsViewController
            else { fatalError("Did not instantiate `SettingsViewController`") }

        let titleSettings = NSLocalizedString("navtab.preferences", comment: "Preferences (aka Settings, Configuration) navigation tab. Choose word different from 'Tweaks' translation")
        tabSettingsViewController.title = titleSettings
        tabSettingsViewController.tabBarItem = UITabBarItem.init(
            title: titleSettings,
            image: UIImage(named: "ic_tabapp_settings"),
            tag: 0
        )
        controllerArray.append(tabSettingsViewController)

        // Main Nav Bar Controller
        var navControllerArray = [UINavigationController]()
        for vc in controllerArray {
            let navController = UINavigationController.init(rootViewController: vc)
            navControllerArray.append(navController)
        }
                
        mainTabBarController.viewControllers = navControllerArray
        if let selectedIndex = selectedIndex {
            mainTabBarController.selectedIndex = selectedIndex
        }
        self.view.addSubview(mainTabBarController.view)
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
}

extension MainViewController: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        completionHandler([.alert, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {

        completionHandler()
    }
}
