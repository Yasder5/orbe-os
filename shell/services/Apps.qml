pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "fuzzy.js" as Fuzzy

// Applications installées : recherche floue et classement par usage.
Singleton {
    id: root

    readonly property var entries: DesktopEntries.applications.values

    function search(query, limit) {
        const counts = usage.counts;
        const results = [];
        for (const entry of entries) {
            const s = query ? Fuzzy.best(query, [entry.name, entry.genericName, entry.keywords.join(" "), entry.comment]) : 0;
            if (s < 0)
                continue;
            // L'usage départage les résultats proches et ordonne la liste quand la recherche est vide.
            results.push({ entry, score: s + Math.min(counts[entry.id] ?? 0, 50) * (query ? 4 : 20) });
        }
        results.sort((a, b) => b.score - a.score || a.entry.name.localeCompare(b.entry.name));
        return results.slice(0, limit ?? 40).map(r => r.entry);
    }

    function launch(entry) {
        const counts = Object.assign({}, usage.counts);
        counts[entry.id] = (counts[entry.id] ?? 0) + 1;
        usage.counts = counts;
        entry.execute();
    }

    FileView {
        path: Quickshell.statePath("apps.json")
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: usage

            property var counts: ({})
        }
    }
}
