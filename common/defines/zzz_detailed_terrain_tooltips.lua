-- High-contrast vanilla F5 terrain map mode.
-- Despite the vanilla comment calling these "transparency", in current HOI4
-- they behave as overlay strength for this mode. Keep them at 1.0 so F5 has
-- visible terrain colors.
NDefines_Graphics.NMapMode.MAP_MODE_TERRAIN_TRANSPARENCY = 1.0
NDefines_Graphics.NMapMode.MAP_MODE_NAVAL_TERRAIN_TRANSPARENCY = 1.0

-- Use a small positive terrain override, not 0.0.
-- 0.0 disables the override and makes close zoom fall back toward the normal
-- 3D terrain; 0.39 keeps close zoom usable but lets country color bleed through
-- at strategic zoom. 0.05 keeps the terrain channel fully filled at all zooms,
-- so far-zoom country color no longer tints F5 terrain.
NDefines_Graphics.NGraphics.GRADIENT_BORDERS_CAMERA_DISTANCE_OVERRIDE_TERRAIN = 0.05


-- Make delayed tooltips appear almost immediately. This is global UI behavior.
NDefines_Graphics.NGraphics.TOOLTIP_DELAYED_DELAY = 0.05
NDefines_Graphics.NGraphics.TOOLTIP_SHOW_DELAY = 0.01
NDefines_Graphics.NGraphics.TOOLTIP_HIDE_DELAY = 0.01
