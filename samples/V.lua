-- This is a real spec saved from my playthrough.
-- You can drop this to the specs directory to try to load.
return {
	Character = {
		Level = 50,
		StreetCred = 50,

		Attributes = {
			Body = 20,
			Reflexes = 18,
			TechnicalAbility = 20,
			Intelligence = 10,
			Cool = 3,
		},

		Skills = {
			Athletics = 20,
			Annihilation = 20,
			StreetBrawler = 11,
			Assault = 18,
			Handguns = 18,
			Blades = 15,
			Crafting = 19,
			Engineering = 20,
			BreachProtocol = 9,
			Quickhacking = 10,
			Stealth = 3,
			ColdBlood = 3,
		},

		Perks = {
			Athletics = {
				Regeneration = 1, -- Max: 1 / Health slowly regenerates during combat.
				SteelAndChrome = 2, -- Max: 2 / Increases melee damage by 10/20%.
				DividedAttention = 1, -- Max: 1 / Allows you to reload weapons while sprinting, sliding, and vaulting.
				Multitasker = 1, -- Max: 1 / Allows you to shoot while sprinting, sliding, and vaulting.
				LikeAButterfly = 1, -- Max: 1 / Dodging does not drain Stamina.
				DogOfWar = 2, -- Max: 2 / Increases Health regen in combat by 15/50%
				Wolverine = 2, -- Max: 2 / Health regen activates 50/90% faster during combat.
				SteelShell = 1, -- Max: 1 / Increases armor by 10%.
				Indestructible = 1, -- Max: 1 / Reduces all damage by 10%.
			},
			Annihilation = {
				HailOfBullets = 3, -- Max: 3 / Shotguns and Light Machine Guns deal 3/6/10% more damage.
				PumpItLouder = 2, -- Max: 2 / Reduces recoil of Shotguns and Light Machine Guns by 10/20%.
				InYourFace = 2, -- Max: 2 / Reduces reload time of Shotguns and Light Machine Guns by 20/40%.
				DeadCenter = 2, -- Max: 2 / Increases damage to torsos by 10/20%.
				Mongoose = 1, -- Max: 1 / Increases Evasion by 25% while reloading.
				Massacre = 3, -- Max: 3 / Increases Crit Damage with Shotguns and Light Machine Guns by 15/30/45%
				SkeetShooter = 1, -- Max: 1 / Deal 15% more damage to moving targets.
				Biathlete = 1, -- Max: 1 / Weapon spread does not increase while moving.
			},
			Assault = {
				Bulletjock = 3, -- Max: 3 / Increases damage with rifles by 3/6/10%.
				Bullseye = 1, -- Max: 1 / Increases Rifle and Sumachine Gun damage while aiming by 10%
				Executioner = 1, -- Max: 1 / Deal 25% more damage with Rifles and Submachine Guns to enemies whose Health is above 50%.
				ShootReloadRepeat = 2, -- Max: 2 / Defeating an enemy with a Rifle or Submachine Gun reduces reload time by 20/40% for 5 seconds.
				DuckHunter = 2, -- Max: 2 / Increases Rifle and Submachine Gun damage to moving enemies by 10/20%
				NervesOfSteel = 2, -- Max: 2 / Increases headshot damage with Sniper Rifles and Rrecision Rifles by 20/30%.
				FeelTheFlow = 2, -- Max: 2 / Reduces reload time for Assault Rifles and Submachine Guns by 10/20%.
				NamedBullets = 1, -- Max: 1 / Increases Crit Damage with Rifles and Submachine Guns by 35%.
				RecoilWrangler = 1, -- Max: 1 / Reduces recoil with Rifles and Submachine Guns by 10%.
				LongShot = 1, -- Max: 1 / Rifle and Submachine Gun damage increases the farther you are located from enemies.
			},
			Handguns = {
				Gunslinger = 3, -- Max: 3 / Reduces reload time for Pistols and Revolvers by 10/15/25%.
				RioBravo = 3, -- Max: 3 / Increases headshot damage multiplier with Pistols and Revolvers by 10/20/30%.
				Desperado = 3, -- Max: 3 / Increases damage with Pistols and Revolvers by 3/6/10%.
				LongShotDropPop = 2, -- Max: 2 / Increases damage with Pistols and Revolvers to enemies 5+ meters away by 15/25%.
				SteadyHand = 1, -- Max: 1 / Reduces Pistol and Revolver recoil by 30%.
				VanishingPoint = 1, -- Max: 1 / Evasion increases by 25% for 6 sec. after performing a dodge with a Pistol or Revolver equipped.
				AFistfulOfEurdollars = 2, -- Max: 2 / Increases Crit Damage with Pistols and Revolvers by 10/20%.
				GrandFinale = 1, -- Max: 1 / The last round in a Pistol or Revolver clip deals double damage.
				AttritionalFire = 1, -- Max: 1 / Firing consecutive shots with a Pistol or Revolver at the same target increases damage by 10%.
				WildWest = 1, -- Max: 1 / Removes the damage penalty from Pistols and Revolvers when shooting from a distance.
				SnowballEffect = 1, -- Max: 1 / After defeating an enemy, fire rate for Pistols and Revolvers increases by 5% for 6 sec. Stacks up to 5 times.
				Westworld = 1, -- Max: 1 / Increases Crit Chance for Pistols and Revolvers by 10% if fully modded.
			},
			Blades = {
				StingLikeABee = 3, -- Max: 3 / Increases attack speed with Blades by 10/20/30%.
				FlightOfTheSparrow = 2, -- Max: 2 / Reduces the Stamina cost of all attack with Blades by 30/50%
				ShiftingSands = 2, -- Max: 3 / Dodging recovers 15/20/25% Stamina.
				BlessedBlade = 1, -- Max: 1 / Increases Crit Chance with Blades by 20%.
				FieryBlast = 1, -- Max: 3 / Increases damage with Blades by 1/2/3% for every 1% of Health the enemy is missing.
				JudgeJuryAndExecutioner = 1, -- Max: 3 / Increases damage with Blades by 50/75/100% against enemies with max Health.
				Deathbolt = 1, -- Max: 1 / While wielding a Blade, defeating an enemy restores 20% Health and increases movement speed by 30% for 5 sec.
			},
			Crafting = {
				TrueCraftsman = 1, -- Max: 1 / Allows you to craft Rare items.
				FieldTechnician = 2, -- Max: 2 / Crafted weapons deals 2.5/5% more damage.
				ExNihilo = 1, -- Max: 1 / Grants a 20% chance to craft an item for free.
				GreaseMonkey = 1, -- Max: 1 / Allows you to craft Epic items.
				WasteNotWantNot = 1, -- Max: 1 / When disassembling an item, you get attached mods back.
				EdgerunnerArtisan = 1, -- Max: 1 / Allows you to craft Legendary items.
			},
			Engineering = {
				Bladerunner = 2, -- Max: 2 / Increase damage to drones, mech and robots by 20/40%.
				Tesla = 3, -- Max: 3 / Increase the charge multiplier for Tech weapons by 15/35/55%.
				Insulation = 1, -- Max: 1 / Grants immunity to shock.
				FuckAllWalls = 1, -- Max: 1 / Reduces the charge amount needed for Tech weapons to penetrate walls by 30%.
				LicketySplit = 2, -- Max: 2 / Tech weapons charge time is reduced by 10/20%.
				Superconductor = 1, -- Max: 1 / Tech weapons ignore Armor.
				Revamp = 1, -- Max: 0+ / Increases damage Tech weapons by 25%, increases charges damage from all chargeable weapons and cyberware by 10%. +1% charge damage per Perk level.
			},
			BreachProtocol = {
				BigSleep = 2, -- Max: 2 / Unlocks the Big Sleep daemon, which disables all cameras in the network for 3/6 min.
				MassVulnerability = 2, -- Max: 2 / Unlocks the Mass Vulnerability daemon, which reduces the Physical Resistance for all enemies in the network by 30% for 3/6 min.
				MassVulnerabilityResistances = 1, -- Max: 1 / Upgrades the Mass Vulnerability daemon, reducing all Resistances for enemies in the network by 30%.
			},
			Quickhacking = {
				ForgetMeNot = 1, -- Max: 1 / Eliminating a target affected by a quickhack instantly recovers 1 RAM unit(s).
				ISpy = 1, -- Max: 1 / Reveals an enemy netrunner when they're attempting to hack you.
				SignalSupport = 2, -- Max: 2 / Increases quickhack duration by 25/50%.
			},
			Stealth = {
				CrouchingTiger = 1, -- Max: 1 / Increases movement speed while sneaking by 20%.
			},
		},

		Progression = {
			StreetBrawler = 1361,
			Blades = 10580,
			Crafting = 27132,
			BreachProtocol = 1644,
		},

		Points = {
			Attribute = 0,
			Perk = 11,
		},
	},

	Equipment = {
		-- ARCHANGEL / Weapon / Power / Legendary
		{
			id = "Preset_Overture_Kerry_Legendary", 
			seed = 2993855342,
			slots = {
				-- OS-1 GIMLETEYE / Uncommon
				{ slot = "Scope", id = "w_att_scope_short_01", seed = 3868463560, upgrade = "Uncommon" }, 
				-- COUNTERMASS / Epic
				{ slot = "Mod1", id = "SimpleWeaponMod11" }, 
				-- PACIFIER / Epic
				{ slot = "Mod2", id = "SimpleWeaponMod03", upgrade = "Epic" }, 
				-- PACIFIER / Epic
				{ slot = "Mod3", id = "SimpleWeaponMod03", upgrade = "Epic" }, 
				-- PACIFIER / Epic
				{ slot = "Mod4", id = "SimpleWeaponMod03", upgrade = "Epic" }, 
			},
			equip = 1,
		},

		-- WIDOW MAKER / Weapon / Tech / Legendary
		{
			id = "Preset_Achilles_Nash_Legendary", 
			seed = 4114643488,
			slots = {
				-- E255 PERCIPIENT / Rare
				{ slot = "Scope", id = "w_att_scope_long_02", seed = 442254023, upgrade = "Rare" }, 
				-- COUNTERMASS / Epic
				{ slot = "Mod1", id = "SimpleWeaponMod11" }, 
				-- WEAKEN / Rare
				{ slot = "Mod2", id = "SimpleWeaponMod13" }, 
				-- CRUNCH / Epic
				{ slot = "Mod3", id = "SimpleWeaponMod01", upgrade = "Epic" }, 
				-- CRUNCH / Epic
				{ slot = "Mod4", id = "SimpleWeaponMod01", upgrade = "Epic" }, 
			},
			equip = 2,
		},

		-- SATORI / Weapon / Melee / Legendary
		{
			id = "Preset_Katana_Saburo_Legendary", 
			seed = 1851745209,
			slots = {
				-- WHITE KNUCKLED / Rare
				{ slot = "Mod1", id = "TygerMeleeWeaponMod" }, 
				-- WHITE KNUCKLED / Rare
				{ slot = "Mod2", id = "TygerMeleeWeaponMod" }, 
				-- WHITE KNUCKLED / Rare
				{ slot = "Mod3", id = "TygerMeleeWeaponMod" }, 
			},
			equip = 3,
		},

		-- MEDIA SET: MEDIA BASEBALL CAP WITH REACTIVE LAYER / Clothing / Head / Legendary
		{
			id = "Media_01_Set_Cap", 
			seed = 2953617070,
			slots = {
				-- ARMADILLO / Epic
				{ slot = "Mod1", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},

		-- CORPO SET: TACTICAL HYBRID CORPORATE GLASSES / Clothing / Face / Legendary
		{
			id = "Corporate_01_Set_Glasses", 
			seed = 2254254692,
			slots = {
				-- BULLY / Legendary
				{ slot = "Mod1", id = "SimpleFabricEnhancer04" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},

		-- TIMEWORN TRENCH COAT / Clothing / Outer Torso / Legendary
		{
			id = "Coat_04_old_02", 
			seed = 1156644295,
			upgrade = "Legendary",
			slots = {
				-- FORTUNA / Legendary
				{ slot = "Mod1", id = "SimpleFabricEnhancer03" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod4", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},

		-- SOLO SET: ULTRATHIN COMPOSITE PRINT SOLO SHIRT / Clothing / Inner Torso / Legendary
		{
			id = "Solo_01_Set_TShirt", 
			seed = 2456603112,
			slots = {
				-- ARMADILLO / Epic
				{ slot = "Mod1", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod4", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},

		-- ROCKER SET: ELASTIC FLAME RESISTANT ROCKER PANTS / Clothing / Legs / Legendary
		{
			id = "Rockerboy_01_Set_Pants", 
			seed = 2948959660,
			slots = {
				-- ARMADILLO / Epic
				{ slot = "Mod1", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},

		-- NETRUNNER SET: HARDENED NETRUNNER BOOTS WITH COMPOSITE INSERT / Clothing / Feet / Legendary
		{
			id = "Netrunner_01_Set_Shoes",
			seed = 2191998712,
			slots = {
				-- ARMADILLO / Epic
				{ slot = "Mod1", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod2", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
				-- ARMADILLO / Epic
				{ slot = "Mod3", id = "SimpleFabricEnhancer01", upgrade = "Epic" }, 
			},
			equip = true,
		},
	},

	Cyberware = {
		-- NETWATCH NETDRIVER MK.5 / Cyberware / Operating System / Legendary
		{
			id = "NetwatchNetdriverLegendaryMKV",
			seed = 1441747907,
			slots = {
				-- SYSTEM RESET / Legendary
				{ slot = "Mod1", id = "SystemCollapseLvl4Program" },
				-- SYNAPSE BURNOUT / Epic
				{ slot = "Mod2", id = "BrainMeltLvl3Program" },
				-- SHORT CIRCUIT / Rare
				{ slot = "Mod3", id = "EMPOverloadLvl2Program" },
				-- REBOOT OPTICS / Rare
				{ slot = "Mod4", id = "BlindLvl2Program" },
				-- PING / Rare
				{ slot = "Mod5", id = "PingLvl2Program" },
			},
			equip = true,
		},

		-- HEAL-ON-KILL / Cyberware / Frontal Cortex / Legendary
		{ id = "HealOnKillLegendary", seed = 1065218999, equip = 1 }, 

		-- LIMBIC SYSTEM ENHANCEMENT / Cyberware / Frontal Cortex / Rare
		{ id = "LimbicSystemEnhancementRare", seed = 3230397378, equip = 2 }, 

		-- VISUAL CORTEX SUPPORT / Cyberware / Frontal Cortex / Uncommon
		{ id = "ImprovedPerceptionUncommon", seed = 2076712113, equip = 3 }, 

		-- KIROSHI OPTICS MK.3 / Cyberware / Ocular System / Epic
		{
			id = "KiroshiOpticsEpic", 
			seed = 305842793,
			slots = {
				-- THREAT DETECTOR / Rare
				{ slot = "Mod1", id = "KiroshiOpticsFragment4" }, 
				-- WEAKSPOT DETECTION / Uncommon
				{ slot = "Mod2", id = "KiroshiOpticsFragment6" }, 
				-- TRAJECTORY ANALYSIS / Legendary
				{ slot = "Mod3", id = "KiroshiOpticsFragment5" }, 
			},
			equip = true,
		},

		-- MICROGENERATOR / Cyberware / Circulatory System / Legendary
		{ id = "MicroGeneratorLegendary", seed = 3033535034, equip = 1 }, 

		-- BIOMONITOR / Cyberware / Circulatory System / Legendary
		{ id = "HealthMonitorLegendary", seed = 3083686144, equip = 2 }, 

		-- BIOCONDUCTOR / Cyberware / Circulatory System / Legendary
		{ id = "BioConductorsLegendary", seed = 2940703132, equip = 3 }, 

		-- DETOXIFIER / Cyberware / Immune System / Rare
		{ id = "ToxinCleanser", seed = 37509607, equip = 1 }, 

		-- SHOCK-N-AWE / Cyberware / Immune System / Common
		{ id = "ElectroshockMechanismCommon", seed = 1724657227, equip = 2 }, 

		-- KERENZIKOV / Cyberware / Nervous System / Legendary
		{ id = "KerenzikovLegendary", seed = 1200218785, equip = 1 }, 

		-- REFLEX TUNERS / Cyberware / Nervous System / Legendary
		{ id = "ReflexRecorderLegendary", seed = 1773080081, equip = 2 }, 

		-- SUBDERMAL ARMOR / Cyberware / Integumentary System / Legendary
		{ id = "SubdermalArmorLegendary", seed = 2197823386, equip = 1 }, 

		-- FIREPROOF COATING / Cyberware / Integumentary System / Rare
		{ id = "FireproofSkin", seed = 1437592899, equip = 2 }, 

		-- SUPRA-DERMAL WEAVE / Cyberware / Integumentary System / Rare
		{ id = "MetalCoveredSkin", seed = 3780897052, equip = 3 }, 

		-- TITANIUM BONES / Cyberware / Legs / Rare
		{ id = "TitaniumInfusedBonesRare", seed = 3076947252, equip = 1 }, 

		-- MICROROTORS / Cyberware / Skeleton / Legendary
		{ id = "CyberRotorsLegendary", seed = 1776570697, equip = 2 }, 

		-- SMART LINK / Cyberware / Hands / Legendary
		{ id = "SmartLinkLegendary", seed = 4158208826, equip = true }, 

		-- GORILLA ARMS / Cyberware / Arms / Legendary
		{
			id = "StrongArmsLegendary", 
			seed = 2309621426,
			slots = {
				-- KNUCKLES - PHYSICAL DAMAGE / Rare
				{ slot = "Knuckles", id = "PhysicalDamageKnuckles" }, 
				-- BLACK MARKET BATTERY / Legendary
				{ slot = "Battery", id = "AnimalsStrongArmsBattery1" }, 
				-- SENSORY AMPLIFER - CRIT DAMAGE / Rare
				{ slot = "Mod", id = "ArmsCyberwareSharedFragment2" }, 
			},
			equip = true,
		},

		-- REINFORCED TENDONS / Cyberware / Legs / Rare
		{ id = "BoostedTendonsRare", seed = 3292313404, equip = true }, 

		-- GASH ANTIPERSONNEL GRENADE / Grenade / Epic
		{ id = "GrenadeCuttingRegular", equip = 1, qty = 8 }, 

		-- MAXDOC MK.1 / Consumable / Meds / Uncommon
		{ id = "FirstAidWhiffV0", equip = 3, qty = 149 }, 
	},

	Crafting = {
		Components = {
			CommonItem = 23466,
			UncommonItem = 13685,
			RareItem = 7402,
			RareUpgrade = 15908,
			EpicItem = 1107,
			EpicUpgrade = 4244,
			LegendaryItem = 363,
			LegendaryUpgrade = 612,
			UncommonQuickhack = 1054,
			RareQuickhack = 613,
			EpicQuickhack = 230,
			LegenaryQuickhack = 98,
		},
		Recipes = {
			"Preset_Kenshin_Frank_Legendary", -- APPARITION / Legendary
			"Preset_Overture_Kerry_Epic", -- ARCHANGEL / Epic
			"Preset_Overture_Kerry_Legendary", -- ARCHANGEL / Legendary
			"Preset_Zhuo_Eight_Star", -- BA XING CHONG / Legendary
			"BonesMcCoy70V0", -- BOUNCE BACK MK.1 / Uncommon
			"BonesMcCoy70V1", -- BOUNCE BACK MK.2 / Rare
			"BonesMcCoy70V2", -- BOUNCE BACK MK.3 / Epic
			"Preset_Nekomata_Breakthrough", -- BREAKTHROUGH / Epic
			"Preset_Nekomata_Breakthrough_Legendary", -- BREAKTHROUGH / Legendary
			"Preset_Pulsar_Buzzsaw", -- BUZZSAW / Rare
			"Preset_Pulsar_Buzzsaw_Epic", -- BUZZSAW / Epic
			"CarryCapacityBooster", -- CAPACITY BOOSTER / Uncommon
			"Preset_Kenshin_Royce_Epic", -- CHAOS / Epic
			"GrenadeIncendiaryRegular", -- CHAR INCENDIARY GRENADE / Uncommon
			"GrenadeIncendiarySticky", -- CHAR INCENDIARY GRENADE / Rare
			"GrenadeIncendiaryHoming", -- CHAR INCENDIARY GRENADE / Epic
			"Preset_Katana_Cocktail_Epic", -- COCKTAIL STICK / Epic
			"Preset_Burya_Comrade", -- COMRADE'S HAMMER / Epic
			"Preset_Burya_Comrade_Legendary", -- COMRADE'S HAMMER / Legendary
			"Preset_Cane_Fingers_Epic", -- COTTONMOUTH / Epic
			"Preset_Overture_River_Legendary", -- CRASH / Legendary
			"DisableCyberwareProgram", -- CYBERWARE MALFUNCTION / Uncommon
			"SimpleFabricEnhancer01", -- ARMADILLO
			"SimpleFabricEnhancer05", -- BACKPACKER
			"PowerfulFabricEnhancer03", -- PANACEA / Legendary
			"SimpleFabricEnhancer02", -- RESIST!
			"ArmsCyberwareSharedFragment4", -- SENSORY AMPLIFER - ARMOR / Rare
			"AnimalsBerserkFragment1", -- BEAST MODE / Legendary
			"SlowRotor", -- SLOW ROTOR / Rare
			"SandevistanFragment4", -- SANDEVISTAN: HEATSINK
			"Preset_Sidewinder_Divided_Epic", -- DIVIDED WE STAND / Epic
			"Preset_Lexington_Wilson_Rare", -- DYING NIGHT / Rare
			"GrenadeEMPRegular", -- EMP GRENADE / Uncommon
			"GrenadeEMPSticky", -- EMP GRENADE / Rare
			"GrenadeEMPHoming", -- EMP GRENADE / Epic
			"GrenadeFragRegular", -- F-GX FRAG GRENADE / Common
			"GrenadeFragSticky", -- F-GX FRAG GRENADE / Uncommon
			"GrenadeFragHoming", -- F-GX FRAG GRENADE / Rare
			"Preset_Saratoga_Maelstrom_Epic", -- FENRIR / Epic
			"Preset_Yukimura_Kiji_Legendary", -- GENJIROH / Legendary
			"Preset_Baseball_Bat_Denny_Epic", -- GOLD PLATED BASEBALL BAT / Epic
			"Preset_Katana_Takemura_Legendary", -- JINCHU-MARU / Legendary
			"Q005_Johnny_Glasses_Epic", -- JOHNNY'S AVIATORS / Epic
			"Q005_Johnny_Pants_Epic", -- JOHNNY'S PANTS
			"Q005_Johnny_Shoes_Epic", -- JOHNNY'S SHOES
			"Q005_Johnny_Shirt_Epic", -- JOHNNY'S TANK TOP
			"Preset_Liberty_Yorinobu_Epic", -- KONGOU / Epic
			"Preset_Nue_Jackie_Epic", -- LA CHINGONA DORADA / Epic
			"Preset_Omaha_Suzie_Epic", -- LIZZIE / Epic
			"FirstAidWhiffV0", -- MAXDOC MK.1 / Uncommon
			"FirstAidWhiffV1", -- MAXDOC MK.2 / Rare
			"FirstAidWhiffV2", -- MAXDOC MK.3 / Epic
			"GrenadeBiohazardRegular", -- MOLODETS BIOHAZ GRENADE / Uncommon
			"Preset_Ajax_Moron", -- MORON LABE / Epic
			"Preset_Ajax_Moron_Legendary", -- MORON LABE / Legendary
			"Preset_Carnage_Mox_Epic", -- MOX / Epic
			"Preset_Grad_Buck_Legendary", -- O'FIVE / Legendary
			"OverheatLvl3Program", -- OVERHEAT / Epic
			"Preset_Grad_Panam_Epic", -- OVERWATCH / Epic
			"OxyBooster", -- OXY BOOSTER / Common
			0xBCFB0A1216, -- OZOB'S NOSE / Legendary
			"Preset_Liberty_Dex_Epic", -- PLAN B / Epic
			"Preset_Saratoga_Raffen_Epic", -- PROBLEM SOLVER / Epic
			"Preset_Copperhead_Genesis", -- PSALM 11:6 / Rare
			"Preset_Copperhead_Genesis_Epic", -- PSALM 11:6 / Epic
			"MemoryBooster", -- RAM JOLT / Uncommon
			"GrenadeReconRegular", -- RECON GRENADE / Uncommon
			"SQ031_Samurai_Jacket_Epic", -- REPLICA OF JOHNNY'S SAMURAI JACKET / Epic
			"SimpleWeaponMod04", -- COMBAT AMPLIFIER / Rare
			"SimpleWeaponMod01", -- CRUNCH
			"SimpleWeaponMod03", -- PACIFIER
			"SimpleWeaponMod02", -- PENETRATOR
			"Preset_Katana_Saburo_Epic", -- SATORI / Epic
			"Preset_Katana_Saburo_Legendary", -- SATORI / Legendary
			"Preset_Katana_Surgeon_Epic", -- SCALPEL / Epic
			"EMPOverloadLvl2Program", -- SHORT CIRCUIT / Rare
			"Preset_Dildo_Stout_Epic", -- SIR JOHN PHALLUSTIFF / Epic
			"Preset_Igla_Sovereign", -- SOVEREIGN / Epic
			"Preset_Igla_Sovereign_Legendary", -- SOVEREIGN / Legendary
			"StaminaBooster", -- STAMINA BOOSTER / Uncommon
			"Preset_Knife_Stinger_Epic", -- STINGER / Epic
			"SystemCollapseLvl4Program", -- SYSTEM RESET / Legendary
			"Preset_Tactician_Headsman", -- THE HEADSMAN / Epic
			"Preset_Tactician_Headsman_Legendary", -- THE HEADSMAN / Legendary
			"Preset_Baton_Tinker_Bell_Epic", -- TINKER BELL / Epic
			"Preset_Katana_Hiromi_Epic", -- TSUMETOGI / Epic
			"WeaponMalfunctionProgram", -- WEAPON GLITCH / Uncommon
			"Preset_Achilles_Nash_Epic", -- WIDOW MAKER / Epic
			"Preset_Achilles_Nash_Legendary", -- WIDOW MAKER / Legendary
			"GrenadeFlashRegular", -- X-22 FLASHBANG GRENADE / Common
			"GrenadeFlashHoming", -- X-22 FLASHBANG GRENADE / Rare
			"Preset_Dian_Yinglong", -- YINGLONG / Legendary
		},
	},
}