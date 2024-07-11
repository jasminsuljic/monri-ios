# Monri iOS SDK

The Monri iOS SDK makes it easy to build an excellent payment experience in your iOS app. It provides powerful, customizable, UI elements to use out-of-the-box to collect your users' payment details.

We also expose the low-level APIs that power those elements to make it easy to build fully custom forms. This guide will take you all the way from integrating our SDK to accepting payments from your users via credit cards.

## Installation/Configuration

### Install and configure the SDK
You can choose to install the Monri iOS SDK via CocoaPods or via Swift Package Manager.

####CocoaPods

1. If you haven't already, install the latest version of [CocoaPods](https://guides.cocoapods.org/using/getting-started.html)
2. Add this line to your Podfile:
```ruby
pod 'Monri', '~> 1.5'
```
3. Run the following command:
```bash
pod install
```
4.  Don't forget to use the  `.xcworkspace`  file to open your project in Xcode, instead of the  `.xcodeproj`file, from here on out.
5. In the future, to update to the latest version of the SDK, just run:
```bash
pod update Monri
```

For full installation/configuration guide check our wiki page at [Installation Guide](https://github.com/MonriPayments/monri-ios/wiki/Installation-Guide)

####Swift Package Manager 

To install Monri iOS SDK via Swift Package Manager, add the following to your Package.swift file:

```swift
dependencies: [
    .package(url: "https://github.com/MonriPayments/monri-ios", .upToNextMajor(from: "3.0.0"))
]
```

## Version 1.5.0

In version 1.5.0 we have upgraded Alamofire dependency from `~4.0` to `~> 5.2.1`. If you encounter any issues with dependency upgrade let us know through GitHub issues or by sending an email to helpdesk@monri.com`


# Payment API Integration

At some point in the flow of your app you'll obtain payment details from the user. After that you could:
- use obtained payment details and proceed with charge (confirmPayment)
- or tokenize obtained payment details for server side usage

In [Payment API Integration](https://github.com/MonriPayments/monri-ios/wiki/Payment-API-Integration) it's explained how to:
- create payment
- collect payment details
- confirm payment
- get results back on your app and on your backend

If you want to tokenize obtained payment details then continue to the "Tokens API Integration"

# Tokens API Integration

After you've obtained payment details it's easy to securely transfer collected data via Tokens API.

In [Tokens API Integration](https://github.com/MonriPayments/monri-ios/wiki/Tokens-API-Integration) it's explained how to:
- create token request
- create token
- how to use created token for transaction authorization on your backend

# Questions

If you have any questions about documentation/APIs/flow do not hesitate to contact us at support@monri.com
