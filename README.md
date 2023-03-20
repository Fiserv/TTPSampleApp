# Tap to Pay on iPhone Sample App by Fiserv
​
## Purpose
This sample Swift app demonstrates the capabilities of Apple's Tap To Pay on iPhone functionality, leveraging Fiserv's TTP SDK which is [available as a Swift package here](https://github.com/Fiserv/TTPPackage).
​
## Background and setup
You should first read through and understand the steps for obtaining API credentials, etc. that are required for Fiserv's implementation of Tap To Pay.  The Fiserv [TTP Swift Package's README](https://github.com/Fiserv/TTPPackage/blob/main/README.md) has all the info you need.
​
## Structure
This sample app has two Views and a ViewModel as follows:
​
`ContentView` : the entire app UI is contained in this view. It makes calls exclusively to the `FiservTTPViewModel`, which is described below.   This file also contains simple views to display errors and the results of a charge request.  Feel free to change these as desired.
​
`TTPProgressView` : this is just a simple UI control that indicates the app is busy.  Feel free to use your own if you prefer.
​
`FiservTTPViewModel` : this is a view model that interfaces the UI (`ContentView`) with the [Fiserv TTP Package](https://github.com/Fiserv/TTPPackage).  A view model is not strictly required, but it helps separate the UI from the business logic, which is contained in our view model.  Feel free to edit or use your own (or don't use a view model at all if you prefer)
​
## Setup
​
You will need to make a few changes to the sample app to get it to work for you.
​
1. By following the steps in the Fiserv [TTP Swift Package's README](https://github.com/Fiserv/TTPPackage/blob/main/README.md), you should have obtained test API credentials and a test Merchant ID (MID). You need to copy and paste these values at the top of the file `FiservTTPViewModel.swift`.   Follow the instructions provided in the comments at the top of that file.
​
2. You will need to change the Bundle Identifier (and Team) to match the Id of an app that you've provisioned on the [Apple Developer Portal](https://developer.apple.com) with the `com.apple.developer.proximity-reader.payment.acceptance` entitlement.
​
## Running
​
The Xcode simulator supports testing Tap to Pay, but it generates an intentionally invalid payment payload, so calls to authorize will fail.  But it's a good start to see if the other calls are working for you.
​
To run on a physical iPhone against our test environment, you must be logged-into the phone with a 'Sandbox' Apple Id.   Follow Apple's [instructions here](https://developer.apple.com/apple-pay/sandbox-testing/) to create a Sandbox Id.  Note that you must re-start the phone after logging-in with the Sandbox Id.
