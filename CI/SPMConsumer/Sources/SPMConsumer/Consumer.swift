import Rudder_Braze

// Reference the public API from a separate package, without starting either SDK.
public func makeBrazeFactory() -> RudderBrazeFactory {
    RudderBrazeFactory.instance()
}
