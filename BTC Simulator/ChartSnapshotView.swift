//
//  ChartSnapshotView.swift
//  BTCMonteCarlo
//
//  Created by . . on 01/01/2025.
//

import SwiftUI

struct ChartSnapshotView: View {
    let snapshot: UIImage
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .clipped()
                    .padding(.bottom, 80)  // Adjust as needed
                    .ignoresSafeArea(edges: .top)
            }
            .navigationTitle("Monte Carlo – BTC Price (USD)")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
