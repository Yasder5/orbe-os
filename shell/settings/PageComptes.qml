import Quickshell
import Quickshell.Io
import QtQuick
import qs
import qs.components

Column {
    id: page

    property var users: []
    readonly property string me: Quickshell.env("USER") || ""

    width: parent ? parent.width : 700

    FileView {
        path: "/etc/passwd"
        onLoaded: page.users = text().split("\n").map(l => l.split(":")).filter(f => f.length >= 7 && +f[2] >= 1000 && +f[2] < 60000 && !/nologin|false$/.test(f[6])).map(f => ({ name: f[0], display: (f[4] || "").split(",")[0] || f[0] }))
    }

    PageTitle {
        title: "Comptes"
        subtitle: "Les comptes de ce PC. Les changements passent par un terminal, avec le mot de passe administrateur."
    }

    Repeater {
        model: page.users
        ListRow {
            required property var modelData
            width: page.width
            icon: "lock"
            title: modelData.display
            subtitle: modelData.name + (modelData.name === page.me ? " · ce compte" : "")
            selected: modelData.name === page.me
        }
    }

    SettingRow {
        title: "Changer mon mot de passe"
        OButton {
            text: "Changer"
            onClicked: Quickshell.execDetached(["foot", "-T", "Mot de passe", "-H", "passwd"])
        }
    }
    SettingRow {
        title: "Ajouter un compte"
        subtitle: "Compte standard, ou administrateur (groupe wheel)."
        OButton {
            text: "Ajouter"
            onClicked: Quickshell.execDetached(["foot", "-T", "Nouveau compte", "-H", "orbe-add-user"])
        }
    }
}
