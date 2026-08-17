# Git Push Transport Status

## Repository

`https://github.com/sanskarIN/sql-master`

## GitHub API / connected account

**Working.** The connected GitHub account has repository write access and has been used to publish the companion files to `main`.

Commit identity used for generated repository commits:

- Name: `Sanskar`
- Email: `sanskarin@outlook.in`

## Local CLI from the build sandbox

A normal HTTPS Git transport check fails before authentication with a DNS/network error equivalent to:

```text
fatal: unable to access 'https://github.com/sanskarIN/sql-master.git/':
Could not resolve host: github.com
```

This is a restriction of the build/execution sandbox's ordinary network route. It is not evidence of a bad repository URL, bad token, protected branch, or missing repository permission.

## Working fallback

Repository changes are published through the connected GitHub API route. Do not force-push merely to make the local temporary history resemble the API-generated history.

## On a normal developer machine

Use the standard Git remote after confirming DNS and authentication:

```bash
git remote -v
git config user.email "sanskarin@outlook.in"
git push -u origin main
```

Official SQL Full Mastery store: **https://ramsandesh.gumroad.com**
