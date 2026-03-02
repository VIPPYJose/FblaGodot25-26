# Flowing Background

Animated gradient background used on the main menu, settings, and credits screens. Renders as a **ColorRect** with a **ShaderMaterial** that samples a gradient texture and animates it along a configurable direction.

---

## Overview

- **Purpose:** Subtle, seamless animated background for UI screens.
- **Usage:** Applied to a full-screen `ColorRect` node named `BG` in `starting_menu`, `settings`, and `credits` scenes.
- **Material:** `res://assets/effects/materials/flowing_gradient_bg.tres`

---

## Asset Chain

| Asset | Path | Role |
|-------|------|------|
| Shader | `assets/effects/shaders/flowing_gradient.gdshader` | Canvas-item shader: samples gradient, applies flow + optional pixelation |
| Material | `assets/effects/materials/flowing_gradient_bg.tres` | ShaderMaterial that wires the shader to the gradient texture and parameters |
| Gradient texture | `assets/effects/textures/menu_bg_gradient_texture.tres` | 1D gradient (256px wide) built from the gradient below |
| Gradient | `assets/effects/gradients/menu_bg_gradient.tres` | Color stops (warm browns) defining the look |

---

## Shader Parameters (Material)

| Parameter | Type | Current value | Description |
|-----------|------|---------------|-------------|
| `gradient_texture` | Texture2D | `menu_bg_gradient_texture.tres` | 1D gradient sampled along the flow axis |
| `pixel_steps` | float | 128 | Band count: lower = more banded/pixelated, higher = smoother (2–256) |
| `speed` | float | 0.035 | Flow speed; sign controls direction |
| `direction` | Vector2 | (-1, -1) | Flow direction (normalized in shader); e.g. (-1,-1) = upper-right |

---

## How It Works

1. **UV projection:** Fragment UV is projected onto `direction` and offset by `TIME * speed`, then wrapped with `fract()` for a repeating pattern.
2. **Band quantization:** If `pixel_steps` &lt; 128, the position is quantized into steps for a banded look; otherwise the gradient is sampled smoothly.
3. **Sampling:** The gradient texture is sampled at `(sample_pos, 0.5)`, so the gradient runs along the texture’s U axis and flows over time.

The gradient resource uses 7 color stops (warm browns from dark to light and back), giving a continuous, looping color flow.

---

## Customization

- **Colors:** Edit `assets/effects/gradients/menu_bg_gradient.tres` (offsets and colors). Re-export or ensure the GradientTexture1D references it.
- **Speed/direction:** Adjust `speed` and `direction` on the material instance (e.g. in the Inspector when the scene uses the material).
- **Sharp vs smooth:** Lower `pixel_steps` (e.g. 16–32) for a more banded look; keep at 128 or higher for a smooth gradient.

---

## Reusing on New Scenes

1. Add a `ColorRect` (e.g. named `BG`), anchor it full-screen.
2. Assign **Material** → `res://assets/effects/materials/flowing_gradient_bg.tres`.
3. Optionally override `speed`, `direction`, or `pixel_steps` on the material if this scene needs a different look.

No script is required; the shader animates using `TIME`.
