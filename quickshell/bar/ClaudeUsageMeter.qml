import QtQuick
import QtQuick.Layouts

import qs.modules.common
import qs.modules.common.widgets

Rectangle {
    id: root
    radius: Appearance.rounding.small
    color: Appearance.colors.colSurfaceContainerHigh

    property string title: ""
    property string icon: ""
    property real percentage: 0
    property string resetRelative: ""
    property string resetAbsolute: ""

    function thresholdColor(pct) {
        if (pct >= 0.8) return Appearance.m3colors.m3error;
        if (pct >= 0.5) return Appearance.m3colors.m3tertiary;
        return Appearance.m3colors.m3primary;
    }

    readonly property color meterColor: thresholdColor(percentage)

    implicitWidth: contentLayout.implicitWidth + 16 * 2
    implicitHeight: contentLayout.implicitHeight + 12 * 2

    ColumnLayout {
        id: contentLayout
        anchors {
            fill: parent
            margins: 12
            leftMargin: 16
            rightMargin: 16
        }
        spacing: 6

        // Title row
        RowLayout {
            spacing: 6
            MaterialSymbol {
                text: root.icon
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: root.title
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.small
                }
                color: Appearance.colors.colOnSurfaceVariant
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: `${Math.round(root.percentage * 100)}%`
                font {
                    weight: Font.Bold
                    pixelSize: Appearance.font.pixelSize.small
                }
                color: root.meterColor
            }
        }

        // Progress bar
        StyledProgressBar {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            value: root.percentage
            highlightColor: root.meterColor
        }

        // Reset info
        RowLayout {
            spacing: 4
            MaterialSymbol {
                text: "schedule"
                iconSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: root.resetRelative ? `Resets in ${root.resetRelative}  ·  ${root.resetAbsolute}` : ""
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
