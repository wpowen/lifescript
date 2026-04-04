# LifeScript Solo Pages

Static support and legal pages for `LifeScript-Solo`.

Suggested publish targets:

- `privacy.html`
- `support.html`
- `contact.html`
- `content-rating.html`
- `terms.html`

Language behavior:

- Root pages support `zh-Hans`, `en`, `ja`, and `ko`
- Language is resolved from `?lang=`, then local storage, then browser language
- Internal links preserve the selected language
- Older language-specific subdirectories should not be used

These pages are intentionally isolated under `LifeScript-Solo/LegalPages` so they do not interfere with any other app's legal content in this repository.
