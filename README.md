## This repository is archived

This repository is no longer actively maintained. See below for the response Apple gave us.


# swiftui-conditionaloverlay-bug
Conditionally applying an overlay modifier makes the receiving view lose its @State.

## Radar

Radar: **FB8936510**. Submitted to Apple on 2020-12-11. 

## Clear description of the problem:
- When conditionally applying an overlay modifier to a view, the view loses it’s @State & SwiftUI identity once the overlay modifier is applied.

## Code excerpt from ViewModifier:

    @ViewBuilder
    func body(content: Content) -> some View {
        // The bug inducing part of this project.
        if condition {
            content.overlay(overlay())
        } else {
            content
        }
    }

## Step by step instructions to reproduce the problem

- Create a ContentView as the root for the application
- Create an InnerView that keeps @State (e.g. a `count` variable) and displays that @State somewhere (in a `Text`)
- Add that InnerView to the ContentView
- Add a ViewModifier to the InnerView that switches between `content` or `content.overlay(…)`
- Run the project
- Change `@State` in the `InnerView` (e.g. via Button that increases `count`)
- Open the overlay
- Close the overlay
- Check the displayed value of the inner view’s @State

## Expected results

- Overlay shows
- `InnerView` @State stays the same
- `InnerView` view keeps its identity

## Actual results

- Overlay shows
- `InnerView` @State is reset ((in the example case, count is reset to 0) 
- `InnerView` view loses its identity

## Environment:

- Tested on Xcode 12.3 RC and iPadOS 14.3 Beta.
- This bug also occurs in the 14.3 Simulator.
- macOS 10.15.7

## Additional Notes/Motivation:

- Full repro case project is attached.
- Adding `.id(…)` or `Identifiable` to any view did not fix this behavior.
- In our projects, we make extensive use of the `if` and `ifLet` modifiers as described by Federico Zanetello on his blog: https://fivestars.blog/swiftui/conditional-modifiers.html. These are generally very helpful in our view code.
- The problematic ViewModifier `BrokenOverlayModifier` in our repro case uses the same pattern of conditionally applying a modifier to a view. 
- This conditional application seems to be the trigger for this broken behavior. In the repro case there is a version of this modifier that is fixed (`FixedOverlayModifier`). This modifier wraps the conditional into a @ViewBuilder computed property and returns an EmptyView if the condition is not met. This view is then used by unconditionally applying the `overlay` modifier to the `content` view. This method does not break anything/reset @State.
- Only some SwiftUI modifier allow to use the modifiers without an if by passing in an “empty” parameter. As examples: passing `EmptyView()` to `overlay(…)`. Or passing `false` into `view.disabled(…)`.
- Unfortunately, not all SwiftUI modifier/extensions can be worked around with an “empty” argument. Example: `hidden()` accepts no arguments, can only be added via `if` statement. You can only either apply the modifier or not. 
- This has bigger implications than just losing @State. In the moment the @State is lost, SwiftUI also loses the association to any sheets that are currently presented. Imagine a view that uses `@State var sheetShown = false`. In that case, if a sheet is currently being presented (`isSheetShown = true`) and the identity is lost (due to this bug), the sheet is not associated with the (newly created) view anymore. Closing that Sheet (via `isSheetShown = false`) does not work anymore, as SwiftUI has no handle to that Sheet anymore and does not realize that the Sheet that is actually currently presented should be controlled by the View. In addition, sometimes SwiftUI tries to open the same sheet again and therefore triggers a UIKit exception (“attempt to present a viewcontroller on a viewcontroller that is already presenting something”).

## Feedback from Apple

This is expected behavior and a fundamental part of how SwiftUI functions and not a bug. We actually have a WWDC21 video that explain in greater detail why this is the case and I would recommend watching it:

https://developer.apple.com/videos/play/wwdc2021/10022/.

FixedOverlayModifier is a correct way to implement this. Some alternatives for this specific case are also:

```
@ViewBuilder
func body(content: Content) -> some View {
    // As we now consistently apply the overlay modifier to the view,
    // the buggy behavior is not triggered.
    content.overlay {
        if condition {
            overlay()
        }
    }
}
```

```
@ViewBuilder
func body(content: Content) -> some View {
    // As we now consistently apply the overlay modifier to the view,
    // the buggy behavior is not triggered.
    ZStack {
        content
        if condition {
            overlay()
        }
    }
}
```

Please close this feedback report if resolved, or let us know if this is still an issue for you.  Thank you.

Directions for all sysdiagnose logging, screen recording and profiles:
https://developer.apple.com/bug-reporting/profiles-and-logs/
