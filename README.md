# What is RudderStack?

[RudderStack](https://rudderstack.com/) is a **customer data pipeline** tool for collecting, routing and processing data from your websites, apps, cloud tools, and data warehouse.

More information on RudderStack can be found [here](https://github.com/rudderlabs/rudder-server).

## Integrating Braze with RudderStack's iOS SDK

1. Add [Braze](https://www.braze.com) as a destination in the [Dashboard](https://app.rudderstack.com/) and define ```REST api key```, ```App Key``` and ```Data Center Instance```

2. Rudder-Braze is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'Rudder-Braze', '1.0.4'
```

## Initialize ```RSClient```

Put this code in your ```AppDelegate.m``` file under the method ```didFinishLaunchingWithOptions```
```
RSConfigBuilder *configBuilder = [[RSConfigBuilder alloc] init];
[configBuilder withDataPlaneUrl:DATA_PLANE_URL];
[configBuilder withFactory:[RudderBrazeFactory instance]];
RSClient *rudderClient = [RSClient getInstance:WRITE_KEY config:[configBuilder build]];
```

## Send Events

Follow the steps from the [RudderStack iOS SDK](https://github.com/rudderlabs/rudder-sdk-ios).

## Contact Us

If you come across any issues while configuring or using this integration, please feel free to start a conversation on our [Slack](https://resources.rudderstack.com/join-rudderstack-slack) channel. We will be happy to help you.
