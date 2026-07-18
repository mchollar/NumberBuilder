import SwiftUI
import UIKit

/// A `UIPickerView` wrapper standing in for SwiftUI's `.pickerStyle(.wheel)`.
///
/// SwiftUI's built-in wheel picker doesn't expose row height, so oversized row content just
/// overflows into neighboring rows instead of the row growing to fit it. Wrapping `UIPickerView`
/// directly gives us `pickerView(_:rowHeightForComponent:)`, so dice can be drawn at whatever
/// size we want with no overlap — same native scroll physics and fade/perspective look, just
/// sized to fit.
struct DiceWheelPicker: UIViewRepresentable {
    @Binding var selection: Int
    var colorScheme: DiceColorScheme = .rainbow
    var style: DiceRenderStyle = .filledColoredBackground
    /// Which of the three tray positions this is, 0-based -- forwarded to `DiceFaceView` for
    /// `.rainbow`, which rotates by position. Fixed for the lifetime of one picker instance (each
    /// tray slot gets its own `DiceWheelPicker`), so it's not part of the appearance-change cache
    /// invalidation in `updateUIView`.
    var index: Int = 0
    var rowHeight: CGFloat = 64
    var imageSize: CGFloat = 52
    var columnWidth: CGFloat = 112
    var visibleRows: Int = 3

    private var totalHeight: CGFloat { rowHeight * CGFloat(visibleRows) }

    func makeUIView(context: Context) -> UIPickerView {
        let picker = ClearHighlightPickerView()
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator
        picker.selectRow(selection - 1, inComponent: 0, animated: false)
        return picker
    }

    /// Without this, SwiftUI falls back to `UIPickerView`'s own intrinsic/default size (320x216)
    /// for both HStack layout math and the view's real frame -- multiple pickers side by side
    /// then have massively overlapping *real* (hit-testable) bounds despite each rendering
    /// cleanly clipped to its own small visual slot, so touches on one picker can be routed to
    /// a neighbor depending on view stacking order. This is the sanctioned way to tell SwiftUI a
    /// `UIViewRepresentable`'s actual size.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIPickerView, context: Context) -> CGSize? {
        CGSize(width: columnWidth, height: totalHeight)
    }

    func updateUIView(_ picker: UIPickerView, context: Context) {
        let appearanceChanged = context.coordinator.parent.colorScheme != colorScheme
            || context.coordinator.parent.style != style
        context.coordinator.parent = self
        if appearanceChanged {
            context.coordinator.imageCache.removeAll()
            picker.reloadAllComponents()
        }
        let targetRow = selection - 1
        if picker.selectedRow(inComponent: 0) != targetRow {
            picker.selectRow(targetRow, inComponent: 0, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: DiceWheelPicker
        /// Rendering `DiceFaceView` to a `UIImage` via `ImageRenderer` isn't free -- cache by die
        /// value (1...6) so scrolling/row-reuse doesn't re-render the same face repeatedly.
        /// Cleared in `updateUIView` whenever `colorScheme`/`style` actually change.
        var imageCache: [Int: UIImage] = [:]

        init(_ parent: DiceWheelPicker) {
            self.parent = parent
        }

        private func image(forValue value: Int) -> UIImage {
            if let cached = imageCache[value] { return cached }
            let renderer = ImageRenderer(content:
                DiceFaceView(value: value, colorScheme: parent.colorScheme, style: parent.style, index: parent.index, tier: nil)
                    .frame(width: parent.imageSize, height: parent.imageSize)
            )
            renderer.scale = UIScreen.main.scale
            let image = renderer.uiImage ?? UIImage()
            imageCache[value] = image
            return image
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { 6 }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            parent.rowHeight
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            parent.columnWidth
        }

        func pickerView(
            _ pickerView: UIPickerView,
            viewForRow row: Int,
            forComponent component: Int,
            reusing view: UIView?
        ) -> UIView {
            let container: UIView
            let imageView: UIImageView
            if let reused = view, let reusedImageView = reused.subviews.first as? UIImageView {
                container = reused
                imageView = reusedImageView
            } else {
                container = UIView()
                // Every row (selected or not) reads as one flat surface with a die on top; the
                // system's own selection-highlight chrome is separately neutralized in
                // ClearHighlightPickerView below.
                container.backgroundColor = UIColor(named: "InnerSurface")
                imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                    imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: parent.imageSize),
                    imageView.heightAnchor.constraint(equalToConstant: parent.imageSize)
                ])
            }
            imageView.image = image(forValue: row + 1)
            return container
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selection = row + 1
        }
    }
}

/// `UIPickerView` draws its own translucent, rounded-rect selection-indicator behind the
/// centered row as standard chrome (a system behavior since iOS 14 -- `showsSelectionIndicator`
/// is deprecated and does nothing here, and there's no public API to disable or restyle it). It
/// showed through as a stray gray halo behind the selected die, visible in both light and dark
/// mode, even after each row's own container got an opaque background (that fix wasn't enough --
/// the indicator is a separate layer the picker draws on top, not something behind our content).
/// The common workaround: clear the background color of the picker's own top-level chrome
/// subviews after every layout pass. Safe here because our row containers (returned from
/// `viewForRow`) already provide their own opaque fill and don't depend on the picker's internal
/// scrolling container having a visible background of its own.
private final class ClearHighlightPickerView: UIPickerView {
    override func layoutSubviews() {
        super.layoutSubviews()
        for subview in subviews {
            subview.backgroundColor = .clear
        }
    }
}
