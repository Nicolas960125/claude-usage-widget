pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    implicitWidth: rowLayout.implicitWidth + 10 * 2
    implicitHeight: Appearance.sizes.barHeight

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onPressed: event => {
        if (event.button === Qt.RightButton) {
            ClaudeUsage.refresh();
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            text: ClaudeUsage.error ? "error" : "smart_toy"
            iconSize: Appearance.font.pixelSize.large
            opacity: ClaudeUsage.loading ? 0.4 : 1.0
            color: {
                if (ClaudeUsage.error) return Appearance.m3colors.m3error;
                const maxPct = Math.max(ClaudeUsage.sessionPct, ClaudeUsage.weekPct);
                if (maxPct >= 0.8) return Appearance.m3colors.m3error;
                if (maxPct >= 0.5) return Appearance.m3colors.m3tertiary;
                return Appearance.colors.colOnLayer1;
            }
            Layout.alignment: Qt.AlignVCenter

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }
        }

        StyledText {
            visible: true
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: {
                if (ClaudeUsage.error) return "!";
                if (!ClaudeUsage.hasData) return "--";
                return `${Math.round(ClaudeUsage.sessionPct * 100)}%`;
            }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ClaudeUsagePopup {
        id: claudePopup
        hoverTarget: root
    }
}
