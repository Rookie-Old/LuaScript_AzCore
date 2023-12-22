-------------------------------------------------------------------------------------------------------------------
-- ClassLess System by Shikifuyin
-- Target = AzerothCore - WotLK 3.3.5a
-------------------------------------------------------------------------------------------------------------------
-- ClassLess : Server Configuration
-------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------
-- Requirements
local AIO = AIO or require("AIO")

-------------------------------------------------------------------------------------------------------------------
-- Client / Server Setup

-- Server-side Only !

-------------------------------------------------------------------------------------------------------------------
-- Constant Definitions
CLConfig = CLConfig or {}

CLConfig.SpellPointsRate = 1.0
CLConfig.PetSpellPointsRate = 0 --1.0

CLConfig.TalentPointsRate = 1.5
CLConfig.PetTalentPointsRate = 1.0

CLConfig.RequiredTalentPointsPerTier = 0 --5
CLConfig.RequiredPetTalentPointsPerTier = 0 --3

CLConfig.GlyphMajorSlotsRate = 2.0--1.0
CLConfig.GlyphMinorSlotsRate = 2.0--1.0

CLConfig.AbilityResetCosts = { 0, 0, 0, 0, 0, 0 }
--CLConfig.AbilityResetCosts = { 10000, 50000, 100000, 150000, 200000, 350000 } -- in copper, any number of values

