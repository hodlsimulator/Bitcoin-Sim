//
//  ContentOffsetScrollView.swift
//  BTCMonteCarlo
//
//  Created by . . on 29/11/2024.
//

import SwiftUI

struct ContentOffsetScrollView<Content: View>: UIViewRepresentable {
    var content: Content
    @Binding var contentOffset: CGPoint

    init(contentOffset: Binding<CGPoint>, @ViewBuilder content: () -> Content) {
        self._contentOffset = contentOffset
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        let hostedView = UIHostingController(rootView: content).view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = true
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if uiView.contentOffset != contentOffset {
            uiView.setContentOffset(contentOffset, animated: false)
        }
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ContentOffsetScrollView

        init(_ parent: ContentOffsetScrollView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.parent.contentOffset = scrollView.contentOffset
            }
        }
    }
}
