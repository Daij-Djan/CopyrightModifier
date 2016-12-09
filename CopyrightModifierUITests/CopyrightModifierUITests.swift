//
//  CopyrightModifierUITests.swift
//  CopyrightModifierUITests
//
//  Created by Dominik Pich on 6/15/16.
//  Copyright © 2016 Dominik Pich. All rights reserved.
//

import XCTest

class CopyrightModifierUITests: XCTestCase {
        
    func setUpWithPath(_ path: String) -> (testsPath:String, resultsPath:String) {
        let uuidStr = UUID().uuidString

        // Put setup code here. This method is called before the invocation of each test method in the class.
        let url = Bundle(for: type(of: self)).resourceURL
        let testsPath = url!.appendingPathComponent("Tests")
            .appendingPathComponent(path)
            .path
        let resultsPath = url!.appendingPathComponent("Results")
            .appendingPathComponent(path)
            .path
        
        //copy tests to tmp
        let tmpFolderUrl = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(uuidStr)
        let tmpTestsPath = tmpFolderUrl.path
        try! FileManager.default.copyItem(atPath: testsPath, toPath: tmpTestsPath)
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        let app = XCUIApplication()
        app.launchEnvironment = ["UI_TESTING_PATH":tmpTestsPath]
        app.launch()
        
        return (tmpTestsPath, resultsPath)
    }
    
    func testExample() {
        //start
        let paths = setUpWithPath("ToBeIgnored")
        let w = XCUIApplication().windows["CoprightModifier"]
        
        //set options
        w.radioButtons["Use a fixed author                                                          "].click()
        w.radioButtons["Use a fixed creation date                                              "].click()
        w.radioButtons["Use a custom owner                 "].click()
        w.radioButtons["Use a custom year                            "].click()
        w.radioButtons["MIT license                                                             "].click()
        w.checkBoxes["try to match short OSX username to long OSX username"].click()
        
        //enter data
        let datePicker = w.groups.containing(.textField, identifier:"dpich").children(matching: .datePicker).element
        datePicker.click()
        datePicker.typeText("2013")
        datePicker.typeKey("\t", modifierFlags: .shift)
        datePicker.typeText("19")
        datePicker.typeKey("\t", modifierFlags: .shift)
        datePicker.typeText("12")
        
        let thisyear = w.textFields["this year"]
        thisyear.click()
        thisyear.typeText("2013")
        
        let dpichTextField = w.textFields["dpich"]
        dpichTextField.click()
        dpichTextField.typeText("Dominik Pich")
        
        let osxUsernameTextField = w.textFields["osx username"]
        osxUsernameTextField.click()
        osxUsernameTextField.typeText("Dominik Pich")
        
        let textField = w.groups.containing(.checkBox, identifier:"Include hidden files").children(matching: .textField).element(boundBy: 0)
        textField.click()
        textField.typeText(";mylib")

        //run!
        w.buttons["Process Path"].click()
        w.sheets.buttons["Write Files to disk"].click()
        
        
        //open as test
        NSWorkspace.shared().open(URL(fileURLWithPath: paths.testsPath))
        NSWorkspace.shared().open(URL(fileURLWithPath: paths.resultsPath))
    }
}
