# ISO Orbe OS découpée

Branche de stockage seulement (pas de code) : l'ISO `orbe-os-2026.11.19-x86_64.iso` (2,44 Gio), construite par `./build.sh` depuis le commit `1a76350` de `main`, coupée en 28 morceaux de 95 Mo (GitHub refuse les fichiers de plus de 100 Mo). Somme SHA-256 de l'ISO entière : `07525ecc98b4190b079e269e275c6f8ffce2f72441942fb9205386b3fdc16b0e`.

## Récupérer seulement cette branche

```bash
git clone --single-branch --branch iso https://github.com/Yasder5/orbe-os.git orbe-os-iso
```

Pour cloner le code sans ces 2,6 Go : `git clone --single-branch --branch main ...`.

## Recoller l'ISO

Linux ou WSL, dans le dossier cloné :

```bash
cat orbe-os-2026.11.19-x86_64.iso.part-* > orbe-os-2026.11.19-x86_64.iso
```

```bash
sha256sum -c SHA256SUMS --ignore-missing
```

Windows (invite de commandes `cmd`), dans le dossier cloné ; les morceaux sont pris dans l'ordre alphabétique :

```bat
copy /b orbe-os-2026.11.19-x86_64.iso.part-* orbe-os-2026.11.19-x86_64.iso
```

Puis, dans PowerShell, comparer avec la somme ci-dessus :

```powershell
Get-FileHash orbe-os-2026.11.19-x86_64.iso
```

Ensuite : clé USB et points à vérifier dans `docs/test-materiel.md` (branche `main`).
