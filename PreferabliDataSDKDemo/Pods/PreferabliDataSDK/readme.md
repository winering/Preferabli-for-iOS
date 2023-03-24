![Preferabli logo](https://s3.amazonaws.com/winering-production/1ba338a299a0f489e9ceee6bc61bcac4)

## Overview

You can use the Preferabli iOS SDK to integrate Preferabli's powerful preference technology into your applications. Written in Swift 5.0.

## Installation

To begin installation you will need CocoaPods. CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate WineRing into your Xcode project using CocoaPods, specify it in your Podfile:

`pod 'Preferabli'`

Next import the SDK into your application's AppDelegate.swift using  `import Preferabli`.

Now it's time to Initialize In your project's `application:didFinishLaunchingWithOptions:` 

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    Preferabli(token: "API_TOKEN")
}
```

You must have a Preferabli account to acquire an API token. To login / signup, visit https://preferabli.com

Once logged in, head to the `Settings` page to find your API token.

That's it. You're all set to start using the Preferabli SDK.

## Usage

Some parts of the SDK require you to have an identified customer or user, while other parts can be used anonymously. You can perform the following actions anonymously:




These actions can only be used by an identified customer / user:



To login a customer or a user, please use the following:




## Finish
That's it! If you have any other questions feel free to reach out and ask us. Please also check out our demo application (included in this repo) for some good examples on how to utilize the SDK.
