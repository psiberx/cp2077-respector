--
-- The Character section is very simple and self-explanatory.
-- It defines the character level, street cred, attributes, skills,
-- perks, and unused attribute and perks points.
--
return {
	Character = {
		Level = 1,
		StreetCred = 1,

		Attributes = {
			Body = 3,
			Reflexes = 3,
			TechnicalAbility = 3,
			Intelligence = 3,
			Cool = 3,
		},

		Skills = {
			Athletics = 1,
			Annihilation = 1,
			StreetBrawler = 1,
			Assault = 1,
			Handguns = 1,
			Blades = 1,
			Crafting = 1,
			Engineering = 1,
			BreachProtocol = 1,
			Quickhacking = 1,
			Stealth = 1,
			ColdBlood = 1,
		},

		-- Progression in each skill for curren skill level (not from the level 1).
		Progression = {
			Athletics = 0,
			Annihilation = 0,
			StreetBrawler = 0,
			Assault = 0,
			Handguns = 0,
			Blades = 0,
			Crafting = 0,
			Engineering = 0,
			BreachProtocol = 0,
			Quickhacking = 0,
			Stealth = 0,
			ColdBlood = 0,
		},

		-- For perks see "samples/specs/spec-03-perks.lua".
		Perks = {...},

		-- Unused points.
		Points = {
			Perk = 0,
		},
	},
}