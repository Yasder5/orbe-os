// Sélecteur de fond d'écran : « Orbe vivant » (animé), les fonds Orbe, et les images de
// ~/Images/Fonds d'écran. Flèches pour choisir, Entrée pour appliquer, Échap pour fermer.

import Quickshell
import QtQuick
import Qt.labs.folderlistmodel
import qs
import qs.components

Scope {
    id: root

    readonly property string userDir: Quickshell.env("HOME") + "/Images/Fonds d'écran"
    readonly property var names: ({ "orbe": "Orbe", "orbe-centre": "Orbe au centre", "grille": "Grille", "halo": "Halo" })
    readonly property var items: {
        const list = [{ path: "orbe-vivant", name: "Orbe vivant", live: true }];
        for (const model of [systemFolder, userFolder]) {
            for (let i = 0; i < model.count; i++) {
                const base = model.get(i, "fileBaseName");
                list.push({ path: model.get(i, "filePath"), name: names[base] ?? base, live: false });
            }
        }
        return list;
    }

    function apply(index) {
        const item = items[index];
        if (item)
            Config.wallpaper = item.path;
    }

    FolderListModel {
        id: systemFolder

        folder: "file:///usr/share/backgrounds/orbe"
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    FolderListModel {
        id: userFolder

        folder: "file://" + root.userDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
        showDirs: false
    }

    Variants {
        model: Quickshell.screens

        SidePanel {
            id: panel

            namespace: "orbe-wallpaper-picker"
            open: Panels.wallpaperOpen && Panels.isActive(modelData)
            panelWidth: 760
            onCloseRequested: Panels.wallpaperOpen = false

            OText {
                id: title

                text: "Fond d'écran"
                font.pixelSize: Theme.textL
                font.weight: Font.DemiBold
            }

            OText {
                anchors {
                    top: title.bottom
                    topMargin: Theme.space1
                }
                text: "Tes images vont dans ~/Images/Fonds d'écran"
                font.pixelSize: Theme.textS
                color: Theme.muted
            }

            GridView {
                id: grid

                anchors {
                    fill: parent
                    topMargin: 64
                }
                clip: true
                focus: panel.open
                cellWidth: width / 2
                cellHeight: cellWidth * 9 / 16 + 44
                model: root.items
                boundsBehavior: Flickable.StopAtBounds
                highlightFollowsCurrentItem: false
                Keys.onReturnPressed: root.apply(currentIndex)
                Keys.onEnterPressed: root.apply(currentIndex)

                delegate: Item {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool selected: Config.wallpaper === modelData.path

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: frame

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: Theme.space2
                        }
                        height: width * 9 / 16
                        radius: Theme.radiusM
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.line

                        FocusRing {
                            visible: grid.currentIndex === tile.index && grid.activeFocus
                            radius: Theme.radiusM
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: !tile.modelData.live
                            source: tile.modelData.live ? "" : "file://" + tile.modelData.path
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        Orb {
                            anchors.fill: parent
                            anchors.margins: 1
                            visible: tile.modelData.live
                            running: visible && panel.open
                            particles: 360
                            maxFps: 30
                            background: Theme.bg
                            orbCenter: Qt.point(width * 0.68, height * 0.5)
                            orbRadius: height * 0.38
                        }
                    }

                    Row {
                        anchors {
                            top: frame.bottom
                            left: frame.left
                            topMargin: Theme.space2
                        }
                        spacing: Theme.space2

                        Icon {
                            width: 16
                            height: 16
                            visible: tile.selected
                            name: "check"
                            color: Theme.accent
                        }
                        OText {
                            text: tile.modelData.name
                            font.pixelSize: Theme.textS
                            color: tile.selected ? Theme.accent : Theme.text
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = tile.index
                        onClicked: root.apply(tile.index)
                    }
                }
            }
        }
    }
}
