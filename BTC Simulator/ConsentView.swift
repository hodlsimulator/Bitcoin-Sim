//
//  ConsentView.swift
//  BTCMonteCarlo
//
//  Created by . . on 09/02/2025.
//
/*
import SwiftUI
import Sentry

struct ConsentView: View {
    @Binding var showConsent: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Data Collection Consent")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            Text("We collect error logs and usage data to improve the app. Do you consent to share this data?")
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button(action: {
                    UserDefaults.standard.set(false, forKey: "SentryConsentGiven")
                    showConsent = false
                }) {
                    Text("No")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                }
                
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "SentryConsentGiven")
                    SentrySDK.start { options in
                        options.dsn = "https://3ca36373246f91c44a0733a5d9489f52@o4508788421623808.ingest.de.sentry.io/4508788424376400"
                        options.attachViewHierarchy = false
                        options.enableMetricKit = true
                        options.enableTimeToFullDisplayTracing = true
                        options.swiftAsyncStacktraces = true
                        options.enableAppLaunchProfiling = true
                    }
                    showConsent = false
                }) {
                    Text("Yes")
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 10)
        .padding(40)
    }
}
*/
