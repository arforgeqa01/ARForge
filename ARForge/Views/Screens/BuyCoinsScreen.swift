//
//  BuyCoinsScreen.swift
//  ARForge
//
//  Created by ARForgeQA on 9/6/21.
//

import SwiftUI

struct BuyCoinsScreen: View {
    @Binding var isShowing: Bool
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                Text("You have")
                Text("20 coins")
                
                Spacer()

                HStack{
                    Button("Buy 10 coins @ \n USD 0.99") {
                        IAPManager.shared.buy(productID: .coin10)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)


                    
                    Spacer()
                    Button("Buy 100 coins @ \n USD 8.99") {
                        IAPManager.shared.buy(productID: .coin100)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(30)

                }.font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
            }.font(.title)
            .padding(30)
            .navigationTitle("Buy Coins")
            .navigationBarItems(leading: Button("Back", action: {
                self.isShowing = false
            }))
        }.onAppear {
            IAPManager.shared.initialize()
        }
    }
}

struct BuyCoinsScreen_Previews: PreviewProvider {
    static var previews: some View {
        BuyCoinsScreen(isShowing: .constant(true))
    }
}
