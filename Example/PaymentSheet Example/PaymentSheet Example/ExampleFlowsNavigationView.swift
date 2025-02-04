//Below is an example Swift file (e.g., "ExampleFlowsNavigationView.swift") that shows how to present a navigation list linking to each of your specified SwiftUI views. Each destination view is included here as a minimal placeholder so the file compiles cleanly. If you already have these views in separate files, remove the placeholder versions from this file:
//
//--------------------------------------------------
import SwiftUI

@available(iOS 16.0, *)
struct ExampleFlowsNavigationView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("CozyRestaurantCustomFlow",
                               destination: CozyRestaurantCustomFlow())
                NavigationLink("OrionShoesSingleStepExampleView",
                               destination: OrionShoesSingleStepExampleView())
                NavigationLink("FitFlow",
                               destination: FitFlowContentView())
                NavigationLink("HighlandsHotelBookingExample",
                               destination: HighlandsHotelBookingExample())
                NavigationLink("MidnightMarketHorizontalPaymentMethods",
                               destination: MidnightMarketHorizontalPaymentMethods())
                NavigationLink("BooksAndBeansCafeTopUpExample",
                               destination: BooksAndBeansCafeTopUpExample())
                NavigationLink("WanderlustDeferredPaymentExample",
                               destination: WanderlustDeferredPaymentExample())
            }
            .navigationTitle("Example Flows")
        }
    }
}
