-- =========================================================================
-- Reasonable Guarantees - defines override
-- =========================================================================
-- Disables the engine's automatic AI minor-guarantees. World tension caps at
-- 100, so a threshold above 100 is never reached -> native AI minor-guarantees
-- never fire. Focus/event guarantees are untouched. Our decision
-- (common/decisions/rg_guarantee_decisions.txt) re-adds sane ones.
--
-- IMPORTANT: mutate the existing table with a dotted assignment. Do NOT write
-- `NDefines = { ... }` - that REPLACES the whole NDefines table and wipes
-- NAI / NMilitary / NNavy etc., which crashes the game on startup.
--
-- This key lives in the NAI table (it is read by defines_ai.h), NOT NDiplomacy.
-- =========================================================================

NDefines.NAI.TENSION_MIN_FOR_GUARANTEE_VS_MINOR = 200
