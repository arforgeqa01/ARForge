//
//  CreateModelScreen.swift
//  ARForge
//
//  Created by ARForgeQA on 8/30/21.
//

import SwiftUI

struct CreateModelScreen : View {
    @Binding var showComposeForm : Bool
    @State var selected : [Asset] = []
    @State var showAssetPicker = false
    @State var showUploading = false
    @State var selectedConversionMode = "medium"
    @State var inputType = InputAssetType.video
    
    @State var modelJobUseCase: CreateModelJobUseCase? = nil
    @ObservedObject var jobState = CreateJobState()
    
    let conversionModes = ["preview", "reduced", "medium", "full"]

    
    var body: some View{
        
        ZStack{
            VStack {
                ZStack {
                    HStack {
                        Button("Back") {
                            showComposeForm.toggle()
                        }
                        Spacer()
                    }.padding()
                    
                    Text("Compose Form")
                        .font(.title)
                        .bold()
                }
                Spacer()
            }
            
            VStack(spacing: 40) {
                HStack {
                    Text("Input Type")
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                        .foregroundColor(.gray)
                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    
                    Picker(selection: $inputType, label: Text("Input Type")) {
                        ForEach(InputAssetType.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                HStack {
                    Text("Conversion Mode")
                        .multilineTextAlignment(.leading)
                        .font(.callout)
                        .foregroundColor(.gray)
                        .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/)
                    
                    Picker(selection: $selectedConversionMode, label: Text("Conversion Mode")) {
                        ForEach(conversionModes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Button(action: {
                    self.selected.removeAll()
                    self.showAssetPicker.toggle()
                }) {
                    Text(getSelectImageButtonText())
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: UIScreen.main.bounds.width - 40)
                }
                .background(Color.blue)
                .clipShape(Capsule())
                
                
                Button(action: {
                    
                    modelJobUseCase = CreateModelJobUseCase(jobState: jobState, assets: selected, conversionType: selectedConversionMode, inputType: inputType.rawValue)
                    modelJobUseCase?.start()
                    
                    showUploading.toggle()
                    
                }) {
                    Text("Convert")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: UIScreen.main.bounds.width / 2)
                }
                .background(Color.red.opacity((self.selected.count != 0) ? 1 : 0.5))
                .clipShape(Capsule())
                .disabled(self.selected.count == 0)
            }.padding()
            
            if self.showAssetPicker{
                CustomPicker(inputType: inputType, selected: self.$selected, show: self.$showAssetPicker)
            }
            
            if self.showUploading{
                ZStack {
                    Color.black.opacity(0.8).edgesIgnoringSafeArea(.all)
                    VStack {
                        LoadingIndicator(color: .white).padding()
                        Text("Uploading your files. Please wait")
                            .foregroundColor(.white)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
        }
        .onReceive(jobState.$jobStateValue, perform: { val in
            if case CreateJobStateValue.success = val  {
                self.showComposeForm = false
            }
        })
    }
    
    func getSelectImageButtonText() -> String {
        var text = "Select Assets"
        if (selected.count > 0) {
            text = "Selected \(selected.count) Assets"
        }
        return text
    }
}

struct CreateModelScreen_Previews: PreviewProvider {
    static var previews: some View {
        CreateModelScreen(showComposeForm: .constant(true))
    }
}
