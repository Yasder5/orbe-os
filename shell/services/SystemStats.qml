pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Mesures système pour le tableau de bord, toutes les deux secondes, seulement quand « active »
// est vrai (onglet Système affiché) : aucun coût le reste du temps.
Singleton {
    id: root

    property bool active: false
    property real cpu: 0
    property real mem: 0
    property real memUsed: 0
    property real memTotal: 0
    property real cpuTemp: -1
    property real gpu: -1
    property real gpuTemp: -1
    property string gpuName: ""
    property real disk: 0
    property real diskUsed: 0
    property real diskSize: 0
    property real rx: 0
    property real tx: 0
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var rxHistory: []

    property var last: ({})
    readonly property int keep: 60

    function push(list, value) {
        const next = list.concat([value]);
        return next.length > keep ? next.slice(next.length - keep) : next;
    }

    function parse(text) {
        const now = Date.now();
        for (const line of text.trim().split("\n")) {
            const f = line.split(" ");
            switch (f[0]) {
            case "cpu":
                if (last.cpu)
                    cpu = Math.max(0, Math.min(1, (f[1] - last.cpu[0]) / Math.max(1, f[2] - last.cpu[1])));
                last.cpu = [Number(f[1]), Number(f[2])];
                break;
            case "mem":
                memTotal = Number(f[1]) * 1024;
                memUsed = (Number(f[1]) - Number(f[2])) * 1024;
                mem = memTotal > 0 ? memUsed / memTotal : 0;
                break;
            case "cputemp":
                cpuTemp = Number(f[1]) / 1000;
                break;
            case "gpu":
                gpu = Number(f[1]) / 100;
                gpuTemp = Number(f[2]) / 1000;
                gpuName = f.slice(3).join(" ");
                break;
            case "disk":
                diskUsed = Number(f[1]);
                diskSize = Number(f[2]);
                disk = diskSize > 0 ? diskUsed / diskSize : 0;
                break;
            case "net":
                if (last.net) {
                    const seconds = Math.max(0.5, (now - last.net[2]) / 1000);
                    rx = Math.max(0, (f[1] - last.net[0]) / seconds);
                    tx = Math.max(0, (f[2] - last.net[1]) / seconds);
                }
                last.net = [Number(f[1]), Number(f[2]), now];
                break;
            }
        }
        cpuHistory = push(cpuHistory, cpu);
        memHistory = push(memHistory, mem);
        gpuHistory = push(gpuHistory, Math.max(0, gpu));
        rxHistory = push(rxHistory, rx);
    }

    // Octets en texte court : « 3,2 Go », « 840 Ko/s ».
    function bytes(value, perSecond) {
        const units = ["o", "Ko", "Mo", "Go", "To"];
        let i = 0;
        while (value >= 1024 && i < units.length - 1) {
            value /= 1024;
            i++;
        }
        const text = (value < 10 && i > 0 ? value.toFixed(1) : Math.round(value).toString()).replace(".", ",");
        return `${text} ${units[i]}${perSecond ? "/s" : ""}`;
    }

    Process {
        id: probe

        command: ["sh", Quickshell.shellDir + "/scripts/sysinfo.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Timer {
        running: root.active
        repeat: true
        triggeredOnStart: true
        interval: 2000
        onTriggered: probe.running = true
    }
}
