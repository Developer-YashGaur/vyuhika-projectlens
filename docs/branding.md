# Koshvya approved branding

Product: **Koshvya**, by **Vyuhika**. Internal ProjectLens targets and the `com.vyuhika.projectlens` bundle identifier remain stable.

## Phase 2.1 integration

Approved source files are preserved unchanged in `design/branding/`:

- `Koshvya-AppIcon-1024.png`: opaque 1024×1024 PNG, copied byte-for-byte into `AppIcon.appiconset`. Debug and Release select `AppIcon` through `ASSETCATALOG_COMPILER_APPICON_NAME`; Xcode generates the iPhone icon sizes and bundle icon metadata.
- `Koshvya-Logo-Approved.png`: transparent 1448×1086 PNG, copied byte-for-byte into the universal `KoshvyaLogo.imageset`. Home displays the original proportions on a dark backing in both system appearances, with the accessible label “Koshvya by Vyuhika”. The logo remains visible during loading, errors, empty state and recorded totals.

No replacement artwork, recoloring, cropping or additional appearance variants were generated. The icon contains the approved artwork's inset rounded border; it has been retained as supplied. Any future artwork changes need separate design approval.

## Release follow-up

Signing, App Store packaging/privacy disclosures, source ownership records, physical-device review and minimum iOS 17 appearance/accessibility verification remain release work. See [validation](validation.md) for executed checks. The UI branding test records both Home and the iPhone Home Screen in its xcresult attachments.
