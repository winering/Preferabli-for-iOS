# Installation

Follow these steps to get the Preferabli Data SDK up and running inside your application.

## Step 1. Install CocoaPods.

To begin installation you will need CocoaPods. CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, [visit their website](https://cocoapods.org/). 

## Step 2. Import the Preferabli Data SDK into your project.

To integrate the SDK into your Xcode project using CocoaPods, specify it in your Podfile:

```
pod 'PreferabliDataSDK'
```

## Step 3. Initialize the SDK.

Next import the SDK into your application's AppDelegate.swift:

```
import PreferabliDataSDK
```

Now it's time to initialize in your project's `application:didFinishLaunchingWithOptions:`

Use ``Preferabli/initialize(client_interface:integration_id:logging_enabled:)``

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Preferabli.initialize(client_interface: "YOUR_CLIENT_INTERFACE_HERE", integration_id: YOUR_INTEGRATION_ID)
}
```

## Installation complete.

You are ready to start using the Preferabli Data SDK. For more information on how to use the SDK, see <doc:How-to-use>.
