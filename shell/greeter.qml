// Écran de connexion d'Orbe OS (greeter de greetd). Lancé par orbe-greeter dans cage :
//   qs -p /etc/xdg/quickshell/orbe/greeter.qml
// Placé à la racine du shell pour réutiliser Theme.qml et les composants du bureau.

import Quickshell
import QtQuick
import qs.greeter

ShellRoot {
    Greeter {}
}
