import Quick
import Nimble
import Keys
@testable
import Kiosk

class StubKeys: EidolonKeys {
    override func cardflightProductionAPIClientKey() -> String! {
        return "PRODUCTIONAPIKEY"
    }

    override func cardflightProductionMerchantAccountToken() -> String! {
        return "PRODUCTIONACCOUNTTOKEN"
    }

    override func cardflightStagingAPIClientKey() -> String! {
        return "STAGINGAPIKEY"
    }

    override func cardflightStagingMerchantAccountToken() -> String! {
        return "STAGINGACCOUNTTOKEN"
    }
}


class SwipeCreditCardViewControllerTests: QuickSpec {
    override func spec() {
        it("unbinds bidDetails on viewWillDisappear:") {
            let runLifecycleOfViewController = { (bidDetails: BidDetails) -> SwipeCreditCardViewController in
                let subject = SwipeCreditCardViewController.instantiateFromStoryboard(fulfillmentStoryboard)
                subject.bidDetails = bidDetails
                subject.loadViewProgrammatically()
                subject.viewWillDisappear(false)
                return subject
            }

            let bidDetails = testBidDetails()
            runLifecycleOfViewController(bidDetails)

            expect { runLifecycleOfViewController(bidDetails) }.toNot( raiseException() )
        }

        let stubKeys = StubKeys()

        describe("on staging") {
            var subject: SwipeCreditCardViewController!

            beforeEach {
                let appSetup = AppSetup()
                appSetup.useStaging = true

                subject = SwipeCreditCardViewController.instantiateFromStoryboard(fulfillmentStoryboard)
                subject.appSetup = appSetup
                subject.keys = stubKeys
            }

            it("sets up the CardHandler") {
                expect(subject.cardHandler.APIKey) == stubKeys.cardflightStagingAPIClientKey()
                expect(subject.cardHandler.APIToken) == stubKeys.cardflightStagingMerchantAccountToken()
            }
        }

        describe("on production") {
            var subject: SwipeCreditCardViewController!

            beforeEach {
                let appSetup = AppSetup()
                appSetup.useStaging = false

                subject = SwipeCreditCardViewController.instantiateFromStoryboard(fulfillmentStoryboard)
                subject.appSetup = appSetup
                subject.keys = stubKeys
            }

            it("sets up the CardHandler") {
                expect(subject.cardHandler.APIKey) == stubKeys.cardflightProductionAPIClientKey()
                expect(subject.cardHandler.APIToken) == stubKeys.cardflightProductionMerchantAccountToken()
            }
        }
    }
}
