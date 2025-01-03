//
//  SnapshotsDebugView.swift
//  BTCMonteCarlo
//
//  Created by . . on 02/01/2025.
//
import SwiftUI

struct SnapshotsDebugView: View {
    @EnvironmentObject var chartDataCache: ChartDataCache

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Portrait snapshot
                if let portrait = chartDataCache.chartSnapshot {
                    Text("Portrait Snapshot (\(Int(portrait.size.width)) x \(Int(portrait.size.height)))")
                        .foregroundColor(.white)
                    Image(uiImage: portrait)
                        .resizable()
                        .scaledToFit()
                        .border(Color.gray)
                }

                // Landscape snapshot
                if let landscape = chartDataCache.chartSnapshotLandscape {
                    Text("Landscape Snapshot (\(Int(landscape.size.width)) x \(Int(landscape.size.height)))")
                        .foregroundColor(.white)
                    Image(uiImage: landscape)
                        .resizable()
                        .scaledToFit()
                        .border(Color.gray)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
