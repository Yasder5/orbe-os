// Lanceur d'applications (Super) : panneau qui sort de la barre, recherche floue.
// Préfixes : > commande, = calcul, : émoji, / actions, ~ fichiers.
// Clavier : ↑ ↓ (ou Tab) pour choisir, Entrée pour ouvrir, Échap pour fermer.

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs
import qs.components
import qs.services
import "../services/fuzzy.js" as Fuzzy

Scope {
    id: root

    property string query: ""
    property int current: 0
    property var emojis: []
    property var files: []
    readonly property string prefix: ">=:/~".includes(query.charAt(0)) ? query.charAt(0) : ""
    readonly property string term: (prefix ? query.slice(1) : query).trim()
    readonly property var items: compute(query, files, emojis)

    readonly property var modes: [
        { prefix: ">", label: "commande", icon: "command" },
        { prefix: "=", label: "calcul", icon: "calculator" },
        { prefix: ":", label: "émoji", icon: "emoji" },
        { prefix: "/", label: "actions", icon: "action" },
        { prefix: "~", label: "fichiers", icon: "folder" }
    ]

    function close() {
        Panels.launcherOpen = false;
    }

    function activate(index) {
        const item = items[index];
        if (!item || !item.run)
            return;
        item.run();
        if (!item.keepOpen)
            close();
    }

    function copy(text) {
        Quickshell.execDetached(["wl-copy", "--", text]);
    }

    // Construit la liste de résultats selon le préfixe.
    function compute(q, fileList, emojiList) {
        switch (prefix) {
        case ">":
            return commandItems(term);
        case "=":
            return calcItems(term);
        case ":":
            return emojiItems(term, emojiList);
        case "/":
            return actionItems(term);
        case "~":
            return fileItems(term, fileList);
        default:
            return Apps.search(term, 40).map(entry => ({
                title: entry.name,
                subtitle: entry.genericName || entry.comment || "",
                iconSource: Quickshell.iconPath(entry.icon, "application-x-executable"),
                run: () => Apps.launch(entry)
            }));
        }
    }

    function commandItems(cmd) {
        if (!cmd)
            return [{ title: "Tape une commande", subtitle: "Elle sera lancée en arrière-plan ou dans le terminal", icon: "command" }];
        return [
            { title: cmd, subtitle: "Lancer la commande", icon: "command", run: () => Quickshell.execDetached(["sh", "-c", cmd]) },
            { title: cmd, subtitle: "Lancer dans le terminal", icon: "terminal", run: () => Quickshell.execDetached(["foot", "-H", "sh", "-c", cmd]) }
        ];
    }

    function evaluate(expr) {
        const functions = { sqrt: "Math.sqrt", racine: "Math.sqrt", sin: "Math.sin", cos: "Math.cos", tan: "Math.tan",
                            ln: "Math.log", log: "Math.log10", abs: "Math.abs", pi: "Math.PI", round: "Math.round" };
        let e = expr.replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/").replace(/\s+/g, "");
        // Seuls les chiffres, opérateurs, parenthèses et les fonctions ci-dessus sont acceptés.
        if (!e || !/^[\d+\-*/().^]*$/.test(e.replace(/[a-z]+/gi, "")))
            return null;
        let unknown = false;
        e = e.replace(/[a-z]+/gi, word => functions[word.toLowerCase()] ?? (unknown = true, ""));
        if (unknown)
            return null;
        e = e.replace(/\^/g, "**");
        try {
            const value = Function(`"use strict"; return (${e});`)();
            return typeof value === "number" && isFinite(value) ? value : null;
        } catch (error) {
            return null;
        }
    }

    function calcItems(expr) {
        const value = evaluate(expr);
        if (value === null)
            return [{ title: expr ? "Calcul incomplet" : "Tape un calcul", subtitle: "Exemples : 12*7, (3+4)^2, sqrt(2)", icon: "calculator" }];
        const text = Number(value.toPrecision(12)).toString();
        return [{ title: text.replace(".", ","), subtitle: "Entrée : copier le résultat", icon: "calculator", big: true, run: () => root.copy(text) }];
    }

    function emojiItems(q, list) {
        const scored = [];
        for (const item of list) {
            const s = q ? Fuzzy.strict(q, [item.k, item.n]) : (item.k ? 1 : -1);
            if (s >= 0)
                scored.push({ item, s });
            if (!q && scored.length >= 60)
                break;
        }
        if (q)
            scored.sort((a, b) => b.s - a.s);
        return scored.slice(0, 60).map(({ item }) => ({
            title: item.k || item.n,
            subtitle: item.k ? item.n : "",
            emoji: item.e,
            run: () => root.copy(item.e)
        }));
    }

    function actionItems(q) {
        const list = Session.actions.map(a => ({
            title: a.label, subtitle: "Session", icon: a.icon, danger: a.danger, run: () => Session.run(a.id)
        }));
        list.push(
            { title: "Menu de session", subtitle: "Verrouiller, veille, redémarrer, éteindre", icon: "power", run: () => Panels.toggleSession() },
            { title: "Changer de fond d'écran", subtitle: "Apparence", icon: "image", run: () => Panels.toggleWallpaper() },
            { title: "Tableau de bord", subtitle: "Météo, calendrier, système, média", icon: "home", run: () => Panels.toggleDashboard("accueil") },
            { title: "Réglages rapides", subtitle: "Wi-Fi, Bluetooth, son, mode nuit", icon: "settings", run: () => Panels.toggleQuick() },
            { title: Night.enabled ? "Désactiver le mode nuit" : "Activer le mode nuit", subtitle: "Écran", icon: "moon", run: () => Night.toggle() },
            { title: Notifs.doNotDisturb ? "Désactiver Ne pas déranger" : "Activer Ne pas déranger", subtitle: "Notifications", icon: Notifs.doNotDisturb ? "bell" : "bell-off", run: () => Notifs.toggleDoNotDisturb() },
            { title: Config.barVertical ? "Barre en haut de l'écran" : "Barre à gauche de l'écran", subtitle: "Apparence", icon: "apps", run: () => Config.barPosition = Config.barVertical ? "top" : "left" },
            { title: Config.reduceMotion ? "Rétablir les animations" : "Réduire les animations", subtitle: "Accessibilité", icon: "action", run: () => Config.reduceMotion = !Config.reduceMotion }
        );
        if (!q)
            return list;
        return list.map(a => ({ a, s: Fuzzy.best(q, [a.title, a.subtitle]) })).filter(x => x.s >= 0).sort((x, y) => y.s - x.s).map(x => x.a);
    }

    function fileItems(q, list) {
        if (q.length < 2)
            return [{ title: "Tape au moins deux lettres", subtitle: "Recherche dans ton dossier personnel", icon: "folder" }];
        return list.map(path => {
            const name = path.split("/").pop();
            const home = Quickshell.env("HOME");
            return {
                title: name,
                subtitle: path.startsWith(home) ? "~" + path.slice(home.length) : path,
                icon: path.endsWith("/") ? "folder" : "file",
                run: () => Quickshell.execDetached(["xdg-open", path])
            };
        });
    }

    onQueryChanged: {
        current = 0;
        if (prefix === "~")
            fileDelay.restart();
    }

    Connections {
        target: Panels

        function onLauncherOpenChanged() {
            if (Panels.launcherOpen) {
                root.query = Panels.launcherText;
                root.current = 0;
            }
        }
    }

    // Recherche de fichiers : lancée un instant après la dernière frappe.
    Timer {
        id: fileDelay

        interval: 250
        onTriggered: {
            if (root.term.length < 2)
                return;
            finder.running = false;
            finder.command = ["find", Quickshell.env("HOME"), "-maxdepth", "6", "-not", "-path", "*/.*", "-iname", `*${root.term}*`];
            finder.running = true;
        }
    }

    Process {
        id: finder

        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l).slice(0, 40)
        }
    }

    FileView {
        path: Quickshell.shellDir + "/launcher/emojis.json"
        onLoaded: root.emojis = JSON.parse(text())
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property bool open: Panels.launcherOpen && Panels.isActive(modelData)
            readonly property bool vertical: Config.barVertical
            property real progress: open ? 1 : 0

            screen: modelData
            visible: open || progress > 0
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.transparent
            WlrLayershell.namespace: "orbe-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Behavior on progress {
                NumberAnimation {
                    duration: Theme.durMed
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.curve
                }
            }

            // Clic en dehors du panneau : fermeture.
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            // Le panneau sort de derrière la barre : il est découpé au bord de celle-ci.
            Item {
                x: win.vertical ? Theme.barSize : 0
                y: win.vertical ? 0 : Theme.barSize
                width: win.width - x
                height: win.height - y
                clip: true

                Item {
                    id: panel

                    width: 600
                    height: Math.min(parent.height - Theme.space4 * 2, 680)
                    x: Theme.space3 - (win.vertical ? (1 - win.progress) * (width + Theme.space3 + 40) : 0)
                    y: Theme.space3 - (win.vertical ? 0 : (1 - win.progress) * (height + Theme.space3 + 40))
                    opacity: win.progress

                    RectangularShadow {
                        anchors.fill: background
                        offset.y: 18
                        blur: 40
                        radius: Theme.radiusL
                        color: Theme.shadow
                    }

                    Rectangle {
                        id: background

                        anchors.fill: parent
                        radius: Theme.radiusL
                        color: Theme.panel
                        border.width: 1
                        border.color: Theme.line
                    }

                    MouseArea {
                        anchors.fill: parent
                    }

                    // Champ de recherche
                    Rectangle {
                        id: field

                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            margins: Theme.space3
                        }
                        height: 52
                        radius: Theme.radiusM
                        color: Theme.surface2
                        border.width: 1
                        border.color: input.activeFocus ? Theme.line2 : Theme.line

                        Icon {
                            id: searchIcon

                            anchors {
                                left: parent.left
                                leftMargin: Theme.space4
                                verticalCenter: parent.verticalCenter
                            }
                            name: root.prefix ? root.modes.find(m => m.prefix === root.prefix).icon : "search"
                            color: root.prefix ? Theme.accent : Theme.muted
                        }

                        TextInput {
                            id: input

                            anchors {
                                left: searchIcon.right
                                right: parent.right
                                leftMargin: Theme.space3
                                rightMargin: Theme.space4
                                verticalCenter: parent.verticalCenter
                            }
                            focus: win.open
                            color: Theme.text
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.textOnAccent
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.textL
                            clip: true
                            onTextEdited: root.query = text
                            Component.onCompleted: text = root.query

                            Connections {
                                target: root

                                function onQueryChanged() {
                                    if (input.text !== root.query)
                                        input.text = root.query;
                                }
                            }

                            OText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text === ""
                                text: "Rechercher une application"
                                color: Theme.muted
                                font.pixelSize: Theme.textL
                            }

                            Keys.onPressed: event => {
                                const count = root.items.length;
                                if (event.key === Qt.Key_Escape) {
                                    root.close();
                                } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                    root.current = Math.min(count - 1, root.current + 1);
                                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                                    root.current = Math.max(0, root.current - 1);
                                } else if (event.key === Qt.Key_PageDown) {
                                    root.current = Math.min(count - 1, root.current + 6);
                                } else if (event.key === Qt.Key_PageUp) {
                                    root.current = Math.max(0, root.current - 6);
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.activate(root.current);
                                } else {
                                    return;
                                }
                                event.accepted = true;
                            }
                        }
                    }

                    // Préfixes disponibles, quand la recherche est vide.
                    Row {
                        id: chips

                        anchors {
                            top: field.bottom
                            left: parent.left
                            right: parent.right
                            margins: Theme.space3
                        }
                        spacing: Theme.space2
                        visible: root.query === ""
                        height: visible ? 30 : 0

                        Repeater {
                            model: root.modes

                            Rectangle {
                                required property var modelData

                                height: 30
                                width: chipLabel.implicitWidth + Theme.space3 * 2
                                radius: Theme.radiusS
                                color: chipMouse.containsMouse ? Theme.surface2 : Theme.transparent
                                border.width: 1
                                border.color: Theme.line

                                OText {
                                    id: chipLabel

                                    anchors.centerIn: parent
                                    textFormat: Text.StyledText
                                    text: `<font color="${Theme.accent}">${modelData.prefix}</font>&nbsp; ${modelData.label}`
                                    mono: true
                                    font.pixelSize: Theme.textXs
                                    color: Theme.muted
                                }

                                MouseArea {
                                    id: chipMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.query = modelData.prefix;
                                        input.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: list

                        anchors {
                            top: chips.visible ? chips.bottom : field.bottom
                            left: parent.left
                            right: parent.right
                            bottom: footer.top
                            margins: Theme.space3
                        }
                        clip: true
                        spacing: 2
                        model: root.items
                        currentIndex: root.current
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: Theme.durFast
                        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                        delegate: Item {
                            id: row

                            required property var modelData
                            required property int index
                            readonly property bool selected: ListView.isCurrentItem
                            readonly property bool big: modelData.big ?? false

                            width: list.width
                            height: big ? 76 : 52

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusM
                                color: row.selected ? Theme.surface2 : Theme.transparent

                                FocusRing {
                                    visible: row.selected && !!row.modelData.run
                                    radius: Theme.radiusM
                                }
                            }

                            // Icône : application, émoji ou icône Orbe.
                            Item {
                                id: glyph

                                anchors {
                                    left: parent.left
                                    leftMargin: Theme.space3
                                    verticalCenter: parent.verticalCenter
                                }
                                width: 32
                                height: 32

                                IconImage {
                                    anchors.fill: parent
                                    visible: !!row.modelData.iconSource
                                    source: row.modelData.iconSource ?? ""
                                    asynchronous: true
                                }
                                Icon {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.icon
                                    name: row.modelData.icon ?? "apps"
                                    color: row.modelData.danger ? Theme.danger : row.selected ? Theme.accent : Theme.muted
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: !!row.modelData.emoji
                                    text: row.modelData.emoji ?? ""
                                    font.pixelSize: 24
                                }
                            }

                            Column {
                                anchors {
                                    left: glyph.right
                                    right: parent.right
                                    leftMargin: Theme.space3
                                    rightMargin: Theme.space3
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: 2

                                OText {
                                    width: parent.width
                                    text: row.modelData.title
                                    font.pixelSize: row.big ? Theme.textXl : Theme.textM
                                    font.weight: row.big ? Font.DemiBold : Font.Medium
                                    mono: row.big
                                    color: row.modelData.danger && row.selected ? Theme.danger : Theme.text
                                }
                                OText {
                                    width: parent.width
                                    visible: text !== ""
                                    text: row.modelData.subtitle ?? ""
                                    font.pixelSize: Theme.textS
                                    color: Theme.muted
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: row.modelData.run ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onEntered: root.current = row.index
                                onClicked: root.activate(row.index)
                            }
                        }

                        OText {
                            anchors.centerIn: parent
                            visible: list.count === 0
                            text: "Aucun résultat"
                            color: Theme.muted
                        }
                    }

                    OText {
                        id: footer

                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                            margins: Theme.space3
                            leftMargin: Theme.space4
                        }
                        height: 24
                        mono: true
                        font.pixelSize: Theme.textXs
                        color: Theme.muted
                        text: "↑ ↓ choisir  ·  Entrée ouvrir  ·  Échap fermer"
                    }
                }
            }
        }
    }
}
