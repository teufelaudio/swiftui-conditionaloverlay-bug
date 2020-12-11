//
//  ContentView.swift
//  SheetAfterBackground
//
//  Created by Luis Reisewitz on 09.12.20.
//

import SwiftUI

// This is the entry point. RootView of the application.
struct ContentView: View {
    @State private var blurOverlayShown = false

    var body: some View {
        // @State of this InnerView instance is reset once the overlay appears
        InnerView(overlayShown: $blurOverlayShown)
            // Not relevant, just for display purposes
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            // IMPORTANT: Here the breaking modifier is applied.
            // Applying this version of the modifier resets InnerView's @State
            // once the overlay is shown.
            .modifier(BrokenOverlayModifier(condition: blurOverlayShown) {
                Overlay(shown: $blurOverlayShown)
            })
            // This version of the modifier does not reset the InnerView's @State
            // once the overlay is shown. Enable this and disable the
            // BrokenOverlayModifier above to test the correct behavior.
//            .modifier(FixedOverlayModifier(condition: blurOverlayShown) {
//                Overlay(shown: $blurOverlayShown)
//            })
    }
}

// Small InnerView that should keep track of its own @State.
struct InnerView: View {
    // IMPORTANT: This count is reset after the overlay is shown.
    @State var count = 0

    /// Controls if the overlay is shown via Button.
    var overlayShown: Binding<Bool>

    var body: some View {
        // Contents of this view does not matter, could be anything.
        VStack(spacing: 20) {
            Button("Increase count. Current: \(count)", action: { count += 1})

            Button("Open Overlay", action: { overlayShown.wrappedValue = true })
        }
    }
}

// Very simple overlay that obstructs the other views. Contents do not matter.
struct Overlay: View {
    /// Allows the clos
    var shown: Binding<Bool>

    var body: some View {
        VStack {
            Text("This is an overlay")
            Button("Close this overlay again") {
                shown.wrappedValue = false
            }
        }
        // Just here to cover the full view.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.green)
    }
}

// IMPORTANT: The crux is in this modifier. The `if` statement seems to make
// InnerView forget its @State & identity.
struct BrokenOverlayModifier<Overlay: View>: ViewModifier {
    init(condition: Bool, @ViewBuilder content: @escaping () -> Overlay) {
        self.condition = condition
        self.overlay = content
    }

    let condition: Bool
    let overlay: () -> Overlay

    @ViewBuilder
    func body(content: Content) -> some View {
        // The bug inducing part of this project.
        if condition {
            content.overlay(overlay())
        } else {
            content
        }
    }
}

struct FixedOverlayModifier<Overlay: View>: ViewModifier {
    init(condition: Bool, @ViewBuilder content: @escaping () -> Overlay) {
        self.condition = condition
        self.overlay = content
    }

    let condition: Bool
    let overlay: () -> Overlay

    @ViewBuilder
    var overlayView: some View {
        if condition {
            overlay()
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        // As we now consistently apply the `overlay` modifier to the view,
        // the buggy behavior is not triggered.
        content.overlay(overlayView)
    }
}
