//
//  ContentView.swift
//  IntegrationTester
//
//  Created by David Estes on 2/8/21.
//

import SwiftUI

struct MainMenu: View {
    var body: some View {
      NavigationView {
          List {
              NavigationLink(destination: ExampleCustomCard()) {
                  Text("Card Example")
              }
          }
          .navigationTitle("Examples")
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenu()
    }
}
