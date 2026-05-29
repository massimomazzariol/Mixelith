# UI Reference: Mixelith

This document describes the HTML prototype as a visual reference for the future Flutter UI. It is not code to be copied and must not be imported as a runtime asset.

Archived prototype: [prototypes/mixelith_ui_mockup.html](prototypes/mixelith_ui_mockup.html)

## Palette

- Dark background: Near-absolute black/blue for the entire app.
- Surface dark: Dark panels slightly elevated above the background.
- Gradient accent: Warm neon orange/red/yellow with optional magenta support for the logo, CTAs, and active states.
- Text primary: Warm white or near white.
- Text secondary: Cool grey, readable but discrete.

Consolidated reference values:

- Background: `#121212`
- Background deep: `#0B0B10`
- Surface: `#1E1E1E`
- Surface elevated: `#2A2A2A`
- Primary accent: `#FF5A1F`
- Secondary accent: `#FF2D55`
- Tertiary accent: `#FFC247`
- Support accent: `#D946EF`
- Text primary: `#E0E0E0`
- Text secondary: `#A0A0A0`

## Vibe

- Minimal.
- Premium.
- Artistic.
- Mobile-first.
- Dark, focused on the image and not on superfluous decoration.

## UX Direction for 0.1.0

0.1.0 must be more product-centric than the technical MVP:

- Home screen with three real or clearly implemented actions: `Take photo`, `Open photo`, `More photos`.
- `Take photo` opens a real camera screen on Android and displays an informative fallback on the Windows preview.
- `Open photo` remains the single-photo import path.
- `More photos` opens a multi-select or queue mode.
- Editor with a central result area and reduced controls.
- Filter rail with clear thumbnails.
- Minimal filter stack view.
- `Clear all filters` button always accessible when the stack is not empty.
- Compare view via toggle or simple swipe, not a dominant slider/handle.
- Export bottom sheet with a discrete `Remove metadata` toggle.

## Elements to Keep in Flutter

- Mixelith gradient logo with a geometric/mosaic icon.
- Dark home screen with a main CTA to import a photo.
- Dark editor.
- Central image preview area.
- Horizontal filter bar.
- Rounded filter chips.
- Visual miniature preview for each filter.
- Minimal filter stack display.
- Warm neon gradient accents.
- Bottom sheets only where useful, e.g., for export or specific choices.

## Elements to Remove or Replace

- Drag-to-compare helper text.
- Compare tool with a dominant handle.
- Long text always visible regarding export metadata.
- Placeholder buttons that look like broken features. `Take photo` is no longer a placeholder.

## Elements to Postpone Beyond 0.1.0

- Advanced filter stack with reordering.
- Removal of individual filters from the stack.
- Advanced settings.
- Multiple grid layouts.
- Share/social integration.

## Flutter Guidelines

- Use Material 3 or standard custom Flutter widgets.
- Replicate the feeling and visual hierarchy, not the HTML/CSS code literally.
- Do not add unnecessary UI libraries.
- Avoid heavy animations.
- Prioritize performance on Android.
- Test layouts on small screens before refining desktop/tablet layouts.
- Keep the focus on import, preview, filtering, and exporting.
- Do not introduce complex UI for advanced batch processing in 0.1.0.

## Translation into Flutter Components

- `MixelithGradientLogo`: Wordmark + geometric mosaic icon.
- `MixelithGradientButton`: Main CTA.
- `MixelithScreenScaffold`: Dark base with minimal gradient.
- `MixelithLoadingOverlay`: Elegant loading overlay for imports and filters.
- `FilterChipBar`: Horizontal list of presets.
- `FilterStackBar`: Minimal list of applied effects.
- `ImagePreviewStage`: Central preview area with black background.
- `CompareToggle`: Non-invasive original/modified control.
- `ExportMetadataToggle`: Discrete control in the export bottom sheet.

## Scope Note

This reference authorizes the design of the camera as a 0.1.0 requirement, but does not authorize share sheets, social integrations, machine learning, backends, logins, analytics, ads, or undocumented UI libraries.
