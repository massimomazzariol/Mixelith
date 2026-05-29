# Filter System Specification: Mixelith

The Mixelith filter system is declarative: each preset describes a category, engine, parameters, and UI limits. For 0.1.0, individual presets must feed into an ordered **filter stack**.

## Engine 0.1.0

### CPU Engine

- Type: `FilterEngineType.cpu`.
- Execution: Pure Dart in `compute` or isolates.
- Use: Structural filters, kernels, mosaic, posterization, glitch, and non-linear manipulations.

### Color Matrix Engine

- Type: `FilterEngineType.colorMatrix`.
- Execution: Flutter's `ColorFilter.matrix`, suitable for quick color tone adjustments.
- Use: Duotone, color shifts, contrast, and linear photographic styles.
- Note for Phase 1E: The 5 default filters are implemented using the CPU engine to maintain consistency between preview and future export.

### Future Engines

- Type: `FilterEngineType.gpuShader` or experimental.
- Out of scope for 0.1.0.
- Allowed only after isolated spike validation and CPU fallback.

## Filter Result

```dart
class FilterResult {
  final List<int>? imageBytes;
  final String? outputPath;
  final int width;
  final int height;
  final String mimeType;
  final Duration processingTime;
  final FilterEngineType engineUsed;
  final bool wasDownscaled;
  final ExportFormat outputFormat;
}
```

## Parameter Rules

- Each preset can expose at most 3 parameters.
- Sliders must be numeric and easy to understand.
- Modifications must be protected by a debounce.
- Obsolete jobs must be canceled or ignored.

## Individual Presets and Filter Stack

0.1.0 must distinguish between:

- **FilterPreset:** A reusable, single definition in the filter rail.
- **AppliedFilter:** An instance of a preset applied to the stack, with concrete parameter values.
- **FilterStack:** An ordered list of `AppliedFilter` instances.

0.1.0 Rules:

- Each tap on a filter adds that filter on top of the previous result.
- `Original` shows the base image without the stack.
- `Clear all filters` empties the stack in a single tap.
- Export applies the full stack.
- Compare compares the original vs. the stack result.
- Stack reordering and single-filter removal are future features, not mandatory for 0.1.0.

## Thumbnail Previews

Each filter in 0.1.0 must have a clear miniature preview in the rail. Thumbnails must be light enough to avoid blocking the UI and readable enough to distinguish the style before applying.

Thumbnails must reflect the current preset, not generic icons.

## The 5 Default Filters in 0.1.0

### 1. Neon Pop

- ID: `neon_pop`
- Category: `colorPop`
- Engine: `cpu`
- Description: Highly saturated, bright, cyber/neon look, suitable for urban scenes and graphic compositions.
- Parameters:
  - `intensity`, default 1.0, range 0.0-1.0
  - `saturation`, default 1.6, range 0.5-2.0
  - `contrast`, default 1.25, range 0.5-2.0
- 0.1.0 Algorithm: Saturation, contrast, slight brightness boost, and a procedural color glow.

### 2. Watercolor Wash

- ID: `watercolor_wash`
- Category: `painting`
- Engine: `cpu`
- Description: Soft watercolor effect, with reduced details and washed-out colors.
- Parameters:
  - `intensity`, default 1.0, range 0.0-1.0
  - `softness`, default 0.7, range 0.0-1.0
  - `color_levels`, default 7.0, range 3.0-12.0
- 0.1.0 Algorithm: Slight blur, detail reduction, soft posterization, and increased brightness.

### 3. Mosaic Tiles

- ID: `mosaic_tiles`
- Category: `mosaic`
- Engine: `cpu`
- Description: Artistic tiles with simplified color values.
- Parameters:
  - `tile_size`, default 18.0, range 6.0-48.0
  - `color_depth`, default 8.0, range 2.0-24.0
  - `intensity`, default 1.0, range 0.0-1.0
- 0.1.0 Algorithm: Block color averaging and color quantization.

### 4. Starry Oil

- ID: `starry_oil`
- Category: `painting`
- Engine: `cpu`
- Description: Painterly oil/starry-inspired filter with intense colors and graphic texture.
- Parameters:
  - `intensity`, default 1.0, range 0.0-1.0
  - `brush_detail`, default 0.7, range 0.0-1.0
  - `color_boost`, default 1.4, range 1.0-2.0
- 0.1.0 Algorithm: Saturation/contrast, controlled posterization, subtle edge enhancement, and procedural texture.

### 5. Graphic Poster

- ID: `graphic_poster`
- Category: `poster`
- Engine: `cpu`
- Description: Pop art/poster print style with high contrast and strong color fields.
- Parameters:
  - `levels`, default 5.0, range 2.0-8.0
  - `contrast`, default 1.35, range 0.8-1.8
  - `edge_detail`, default 0.45, range 0.0-1.0
- 0.1.0 Algorithm: Posterization, contrast boost, and optional edge darkening.

## Artistic Scope

The 0.1.0 filters are procedural and local. They do not claim equivalence to style transfer, generative models, or perfect artistic replication.

## On-Device Style Transfer Research

The procedural filters remain the active product implementation. A separate research spike evaluated offline TensorFlow Lite style transfer because the current procedural effects may not be visually strong enough.

Current decision:

- Primary future target: official TensorFlow Lite arbitrary image stylization, int8 model pair.
- Phase 1J-A license gate: blocked until the exact model binary license and redistribution terms are confirmed.
- No model binary has been committed.
- No TensorFlow Lite dependency has been added.
- No ML filter is exposed in the app.
- Any future ML engine must live under `lib/filters/ml/` or an equivalent isolated adapter layer.
- UI code must not import ML runtimes.
- Existing procedural presets must remain available as fallback.
- No runtime downloads are allowed.
- No public filter label may use artist names.

See `docs/ML_STYLE_TRANSFER_RESEARCH.md` for the candidate matrix and `docs/THIRD_PARTY_LICENSES.md` for the license gate ledger.

## 0.1.0 Calibration

The current filters are a technical base but must be calibrated on real photos for 0.1.0:

- Neon Pop must appear clearly neon, saturated, and bright.
- Watercolor Wash must read as a soft watercolor painting, not just blur/posterization.
- Mosaic Tiles must be immediately recognizable as mosaic tiles.
- Starry Oil must have a noticeable painterly texture.
- Graphic Poster must look like a high-contrast print or poster.
- If a filter is not convincing on real photos, it must be calibrated or replaced before 0.1.0.

## Phase 3 Extension Filters

- `mosaic_hard`, CPU, parameters `tile_size`, `gap`.
- `mosaic_soft`, CPU, parameter `tile_size`.
- `ink_sketch`, CPU, parameters `stroke`, `sensitivity`.
- `comic_edge`, CPU, parameters `thickness`, `saturation`.
- `cyberpunk_color`, color matrix, parameter `neon_hue`.
- `dream_blur`, CPU, parameter `radius`.
- `glitch_lite`, CPU, parameter `shift`.
- `noise_grain`, CPU, parameter `grain_amount`.
- `warm_print`, color matrix, parameter `yellowing`.
- `cold_print`, color matrix, parameter `cooling`.

## 0.1.0 Constraints

- Do not implement machine learning.
- Do not introduce GPU libraries or shaders in production.
- Do not introduce `flutter_mosaic` or `flutter_image_filters` in 0.1.0.
- Do not promise constant performance for massive images.
