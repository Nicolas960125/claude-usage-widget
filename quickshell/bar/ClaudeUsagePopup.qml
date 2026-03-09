import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar

StyledPopup {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        // Header
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            MaterialSymbol {
                text: "smart_toy"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3primary
            }
            StyledText {
                text: "Claude Code"
                font {
                    weight: Font.Bold
                    pixelSize: Appearance.font.pixelSize.normal
                }
                color: Appearance.m3colors.m3primary
            }
        }

        // Session (5h)
        ClaudeUsageMeter {
            title: "Session (5h)"
            icon: "timer"
            percentage: ClaudeUsage.sessionPct
            resetRelative: ClaudeUsage.sessionReset
            resetAbsolute: ClaudeUsage.sessionResetAbs
            Layout.fillWidth: true
        }

        // Week (all models)
        ClaudeUsageMeter {
            title: "Week (all)"
            icon: "date_range"
            percentage: ClaudeUsage.weekPct
            resetRelative: ClaudeUsage.weekReset
            resetAbsolute: ClaudeUsage.weekResetAbs
            Layout.fillWidth: true
        }

        // Week (Sonnet)
        ClaudeUsageMeter {
            visible: ClaudeUsage.sonnetPct > 0
            title: "Week (Sonnet)"
            icon: "music_note"
            percentage: ClaudeUsage.sonnetPct
            resetRelative: ClaudeUsage.sonnetReset
            resetAbsolute: ClaudeUsage.sonnetResetAbs
            Layout.fillWidth: true
        }

        // Footer: last refresh + refresh button
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            StyledText {
                text: ClaudeUsage.lastRefresh ? `Updated ${ClaudeUsage.lastRefresh}` : ""
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.smaller
                }
                color: Appearance.colors.colOnSurfaceVariant
            }

            MouseArea {
                id: refreshButton
                width: refreshIcon.width + 8
                height: refreshIcon.height + 4
                cursorShape: Qt.PointingHandCursor
                enabled: !ClaudeUsage.loading
                onClicked: ClaudeUsage.refresh()

                MaterialSymbol {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: Appearance.font.pixelSize.small
                    color: refreshButton.containsMouse
                        ? Appearance.m3colors.m3primary
                        : Appearance.colors.colOnSurfaceVariant
                    opacity: ClaudeUsage.loading ? 0.4 : 1.0

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }
            }
        }
    }
}
