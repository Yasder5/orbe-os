pragma Singleton

import Quickshell
import QtQuick
import qs

// Météo par Open-Meteo, sans clé d'API. Ville réglable (Config.weatherCity), actualisée
// toutes les 30 minutes. Hors ligne : « Météo indisponible ».
Singleton {
    id: root

    property string place: ""
    property var current: null
    property var days: []
    property bool failed: false

    readonly property string city: Config.weatherCity

    // Codes météo de l'OMM vers un libellé et une icône Orbe.
    function describe(code) {
        if (code === 0) return { label: "Ciel dégagé", icon: "sun" };
        if (code <= 2) return { label: "Peu nuageux", icon: "sun" };
        if (code === 3) return { label: "Couvert", icon: "cloud" };
        if (code <= 48) return { label: "Brouillard", icon: "fog" };
        if (code <= 57) return { label: "Bruine", icon: "rain" };
        if (code <= 67) return { label: "Pluie", icon: "rain" };
        if (code <= 77) return { label: "Neige", icon: "snow" };
        if (code <= 82) return { label: "Averses", icon: "rain" };
        if (code <= 86) return { label: "Averses de neige", icon: "snow" };
        return { label: "Orage", icon: "storm" };
    }

    function get(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    done(JSON.parse(xhr.responseText));
                    return;
                } catch (e) {}
            }
            root.failed = true;
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function refresh() {
        if (!city)
            return;
        failed = false;
        get(`https://geocoding-api.open-meteo.com/v1/search?count=1&language=fr&format=json&name=${encodeURIComponent(city)}`, geo => {
            const r = geo.results && geo.results[0];
            if (!r) {
                root.failed = true;
                return;
            }
            root.place = r.name;
            get(`https://api.open-meteo.com/v1/forecast?latitude=${r.latitude}&longitude=${r.longitude}&timezone=auto&forecast_days=5`
                + "&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min", data => {
                const c = data.current;
                // Pas d'étalement d'objet ({ ...x }) : le moteur JavaScript de QML ne le gère pas.
                root.current = Object.assign({ temperature: Math.round(c.temperature_2m), feels: Math.round(c.apparent_temperature),
                                               wind: Math.round(c.wind_speed_10m) }, root.describe(c.weather_code));
                root.days = data.daily.time.map((day, i) => Object.assign({
                    date: new Date(day + "T12:00:00"),
                    max: Math.round(data.daily.temperature_2m_max[i]),
                    min: Math.round(data.daily.temperature_2m_min[i])
                }, root.describe(data.daily.weather_code[i])));
            });
        });
    }

    onCityChanged: refresh()

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: 30 * 60 * 1000
        onTriggered: root.refresh()
    }
}
