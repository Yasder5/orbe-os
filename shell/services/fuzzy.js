.pragma library

// Recherche floue : renvoie -1 si la requête ne correspond pas, sinon un score (plus haut = meilleur).
// Ordre : début du texte, puis début d'un mot, puis sous-chaîne, puis lettres dans l'ordre.

function normalize(text) {
    let s = String(text || "").toLowerCase();
    try {
        s = s.normalize("NFD").replace(/[̀-ͯ]/g, "");
    } catch (e) {
        // normalize indisponible : on garde les accents.
    }
    return s;
}

function score(query, text) {
    const q = normalize(query).trim();
    const t = normalize(text);
    if (!q)
        return 0;
    if (!t)
        return -1;
    if (t.startsWith(q))
        return 1000 - t.length;
    const word = t.indexOf(" " + q);
    if (word >= 0)
        return 800 - word - t.length * 0.1;
    const sub = t.indexOf(q);
    if (sub >= 0)
        return 600 - sub - t.length * 0.1;

    // Lettres dans l'ordre, avec bonus pour les suites et les débuts de mot.
    let from = 0, total = 0, previous = -2;
    for (const c of q) {
        if (c === " ")
            continue;
        const found = t.indexOf(c, from);
        if (found < 0)
            return -1;
        total += found === previous + 1 ? 12 : 4;
        if (found === 0 || " -_./".includes(t[found - 1]))
            total += 8;
        previous = found;
        from = found + 1;
    }
    return total - t.length * 0.05;
}

// Meilleur score parmi plusieurs champs, le premier (le nom) comptant davantage.
function best(query, fields) {
    let result = -1;
    for (let i = 0; i < fields.length; i++) {
        const s = score(query, fields[i]);
        if (s >= 0)
            result = Math.max(result, i === 0 ? s : s * 0.7);
    }
    return result;
}

// Correspondance stricte (début, mot ou sous-chaîne), sans lettres éparpillées : pour les longues listes.
function strict(query, fields) {
    let result = -1;
    for (let i = 0; i < fields.length; i++) {
        const s = score(query, fields[i]);
        if (s >= 500)
            result = Math.max(result, i === 0 ? s : s * 0.9);
    }
    return result;
}
