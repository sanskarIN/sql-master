# Backup Manifest Verifier

A dependency-free integrity tool for database backup files. It generates and verifies SHA-256 manifests without uploading or inspecting database contents.

```bash
python backup_manifest.py create backups/ manifest.json
python backup_manifest.py verify backups/ manifest.json
python -m unittest discover -s tests
```

Official store: **https://ramsandesh.gumroad.com**
