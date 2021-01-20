return {
	Inventory = {
		-- CONTAGION / Quickhack / Uncommon
		-- Non-Lethal.
		-- Deals low damage that applies poison to the target.
		-- Spreads to 2 target(s) within 8-meter radius.
		-- Effective against group targets.
		{ id = "ContagionProgram" }, 

		-- CONTAGION / Quickhack / Rare
		-- Non-Lethal.
		-- Deals low damage that applies poison to the target.
		-- Spreads to 2 target(s) within 8-meter radius.
		-- Effective against group targets.
		-- Poison lasts significantly longer.
		{ id = "ContagionLvl2Program" }, 

		-- CONTAGION / Quickhack / Epic
		-- Non-Lethal.
		-- Deals low damage that applies poison to the target.
		-- Spreads to 2 target(s) within 8-meter radius.
		-- Effective against group targets.
		-- Poison lasts significantly longer.
		-- Each subsequent target receives 30% more damage from contagion.
		{ id = "ContagionLvl3Program" }, 

		-- CONTAGION / Quickhack / Legendary
		-- Non-Lethal.
		-- Deals low damage that applies poison to the target.
		-- Spreads to 2 target(s) within 8-meter radius.
		-- Effective against group targets.
		-- Poison lasts significantly longer.
		-- Each subsequent target receives 30% more damage from contagion.
		-- Passive While Equipped: All quickhacks capable of spreading to multiple targets can jump 1 additional time(s).
		{ id = "ContagionLvl4Program" }, 

		-- CRIPPLE MOVEMENT / Quickhack / Uncommon
		-- Disables the target's ability to move from their current position.
		{ id = "LocomotionMalfunctionProgram" }, 

		-- CRIPPLE MOVEMENT / Quickhack / Rare
		-- Disables the target's ability to move from their current position.
		-- Spreads to the nearest enemy within 8 meter(s).
		{ id = "LocomotionMalfunctionLvl2Program" }, 

		-- CRIPPLE MOVEMENT / Quickhack / Epic
		-- Disables the target's ability to move from their current position.
		-- Spreads to the nearest enemy within 8 meter(s).
		-- Affected enemies are also unable to attack.
		{ id = "LocomotionMalfunctionLvl3Program" }, 

		-- CRIPPLE MOVEMENT / Quickhack / Legendary
		-- Disables the target's ability to move from their current position.
		-- Spreads to the nearest enemy within 8 meter(s).
		-- Affected enemies are also unable to attack.
		-- Passive While Equipped: enemies under the effect of any quickhack cannot sprint.
		{ id = "LocomotionMalfunctionLvl4Program" }, 

		-- CYBERPSYCHOSIS / Quickhack / Legendary
		-- Leathal.
		-- Induces a cyberpyschosis-like state in the target, causing them to attack both enemies and allies.
		-- Sets the status of drones, mechs and robots to friendly, making them turn against your enemies.
		-- If no other allies are nearby, the target will commit suicide.
		-- Passive While Equipped: under the effect of any quickhack will no longer try to avoid inflicting friendly fire.
		{ id = "MadnessLvl4Program" }, 

		-- CYBERWARE MALFUNCTION / Quickhack / Uncommon
		-- Disables the target's cyberware abilitie.
		-- Can disable movement or Resistances.
		-- Very effective against fast-moving targets and netrunners.
		{ id = "DisableCyberwareProgram" }, 

		-- CYBERWARE MALFUNCTION / Quickhack / Rare
		-- Disables the target's cyberware abilitie.
		-- Can disable movement or Resistances.
		-- Very effective against fast-moving targets and netrunners.
		-- Spreads to the nearest target within 8-meter(s).
		{ id = "DisableCyberwareLvl2Program" }, 

		-- CYBERWARE MALFUNCTION / Quickhack / Epic
		-- Disables the target's cyberware abilitie.
		-- Can disable movement or Resistances.
		-- Very effective against fast-moving targets and netrunners.
		-- Spreads to the nearest target within 8-meter(s).
		-- Causes a random implant to explode once the effect's duration expires.
		{ id = "DisableCyberwareLvl3Program" }, 

		-- MEMORY WIPE / Quickhack / Rare
		-- Causes the target to exit combat state.
		{ id = "MemoryWipeLvl2Program" }, 

		-- OVERHEAT / Quickhack / Uncommon
		-- Non-Leathal.
		-- Applies Burn to the target, dealing heat damage over time.
		-- Less effective against drones, mechs, and robots.
		{ id = "OverheatProgram" }, 

		-- OVERHEAT / Quickhack / Rare
		-- Non-Leathal.
		-- Applies Burn to the target, dealing heat damage over time.
		-- Less effective against drones, mechs, and robots.
		-- Targets affected by Burn from Overheat are unable to preform actions.
		{ id = "OverheatLvl2Program" }, 

		-- OVERHEAT / Quickhack / Epic
		-- Non-Leathal.
		-- Applies Burn to the target, dealing heat damage over time.
		-- Less effective against drones, mechs, and robots.
		-- Targets affected by Burn from Overheat are unable to preform actions.
		-- Burm from Overheat lasts significantly longer.
		-- .
		{ id = "OverheatLvl3Program" }, 

		-- OVERHEAT / Quickhack / Legendary
		-- Non-Leathal.
		-- Applies Burn to the target, dealing heat damage over time.
		-- Less effective against drones, mechs, and robots.
		-- Targets affected by Burn from Overheat are unable to preform actions.
		-- Burm from Overheat lasts significantly longer.
		-- Targets affected by Burn from Overheat are unable to use cyberware abilities.
		{ id = "OverheatLvl4Program" }, 

		-- PING / Quickhack / Uncommon
		-- Reveals enemeis and devices connected to the local network.
		{ id = "PingProgram" }, 

		-- PING / Quickhack / Rare
		-- Reveals enemeis and devices connected to the local network.
		{ id = "PingLvl2Program" }, 

		-- PING / Quickhack / Epic
		-- Reveals enemeis and devices connected to the local network.
		{ id = "PingLvl3Program" }, 

		-- PING / Quickhack / Legendary
		-- Reveals enemeis and devices connected to the local network.
		-- Highlighted enemies and devices can be scanned and quickhacked through obstacles.
		{ id = "PingLvl4Program" }, 

		-- REBOOT OPTICS / Quickhack / Uncommon
		-- Resets an enemy's optical cyberware, rendering them temporarily blind.
		-- Duration: 15.20 sec.
		{ id = "BlindProgram" }, 

		-- REBOOT OPTICS / Quickhack / Rare
		-- Resets an enemy's optical cyberware, rendering them temporarily blind.
		-- Spreads to the nearest enemy withing 8 meter(s) Duration: 15.20.
		{ id = "BlindLvl2Program" }, 

		-- REBOOT OPTICS / Quickhack / Epic
		-- Resets an enemy's optical cyberware, rendering them temporarily blind.
		-- Spreads to the nearest enemy withing 8 meter(s).
		-- Greatly increases Effect Duration.
		-- Duration 22.80 sec.
		{ id = "BlindLvl3Program" }, 

		-- REBOOT OPTICS / Quickhack / Legendary
		-- Resets an enemy's optical cyberware, rendering them temporarily blind.
		-- Spreads to the nearest enemy withing 8 meter(s).
		-- Greatly increases Effect Duration.
		-- Passive While equiped: Unlocks Optic Jammer daemon for use in Breach Protocal.
		-- Duration 22.80 sec.
		{ id = "BlindLvl4Program" }, 

		-- REQUEST BACKUP / Quickhack / Uncommon
		-- Calls over 1 enemy squad member(s).
		{ id = "CommsCallInProgram" }, 

		-- REQUEST BACKUP / Quickhack / Epic
		-- Calls over 1 enemy squad member(s).
		-- Can be executed on enemies engaged in combat.
		{ id = "CommsCallInLvl3Program" }, 

		-- SHORT CIRCUIT / Quickhack / Uncommon
		-- Non-Leathal.
		-- Deals moderate damage to the target.
		-- Very effective against drones, mechs, robots, and targets with a weakspot.
		{ id = "EMPOverloadProgram" }, 

		-- SHORT CIRCUIT / Quickhack / Rare
		-- Non-Leathal.
		-- Deals moderate damage to the target.
		-- Very effective against drones, mechs, robots, and targets with a weakspot.
		-- Applies an EMP effect to the target for 4 sec.
		{ id = "EMPOverloadLvl2Program" }, 

		-- SHORT CIRCUIT / Quickhack / Epic
		-- Non-Leathal.
		-- Deals moderate damage to the target.
		-- Very effective against drones, mechs, robots, and targets with a weakspot.
		-- Applies an EMP effect to the target for 4 sec.
		-- Deals 30% extra damage to enemies below a High threat level.
		{ id = "EMPOverloadLvl3Program" }, 

		-- SHORT CIRCUIT / Quickhack / Legendary
		-- Non-Leathal.
		-- Deals moderate damage to the target.
		-- Very effective against drones, mechs, robots, and targets with a weakspot.
		-- Applies an EMP effect to the target for 4 sec.
		-- Deals 30% extra damage to enemies below a High threat level.
		-- Passive While Equipped: Crit Hits with any weapon apply this quickhack's Tier 1 effect.
		{ id = "EMPOverloadLvl4Program" }, 

		-- SONIC SHOCK / Quickhack / Uncommon
		-- Deafens the target, Reducing their ability to detect enemy sounds.
		{ id = "CommsNoiseProgram" }, 

		-- SONIC SHOCK / Quickhack / Rare
		-- Deafens the target, Reducing their ability to detect enemy sounds.
		-- Prevents target from communicating with their allies about your activity.
		{ id = "CommsNoiseLvl2Program" }, 

		-- SONIC SHOCK / Quickhack / Epic
		-- Deafens the target, Reducing their ability to detect enemy sounds.
		-- Prevents target from communicating with their allies about your activity.
		-- Excludes the target from their allies' audio and visual preception systems, Causing them to be completely ignored.
		{ id = "CommsNoiseLvl3Program" }, 

		-- SONIC SHOCK / Quickhack / Legendary
		-- Deafens the target, Reducing their ability to detect enemy sounds.
		-- Prevents target from communicating with their allies about your activity.
		-- Excludes the target from their allies' audio and visual preception systems, Causing them to be completely ignored.
		{ id = "CommsNoiseLvl4Program" }, 

		-- SUICIDE / Quickhack / Epic
		-- Leathal.
		-- Forces target to commit suicide.
		{ id = "SuicideLvl3Program" }, 

		-- SUICIDE / Quickhack / Legendary
		-- Leathal.
		-- Forces target to commit suicide.
		-- Passive While Equipped: Causing an enemy to panic reduces the RAM cost of your next Ultimate quickhack by 2.
		{ id = "SuicideLvl4Program" }, 

		-- SYNAPSE BURNOUT / Quickhack / Rare
		-- Deals Moderate damage that scales higher based on how much health the target is missing.
		{ id = "BrainMeltLvl2Program" }, 

		-- SYNAPSE BURNOUT / Quickhack / Epic
		-- Deals Moderate damage that scales higher based on how much health the target is missing.
		-- Less effective against drones, mech and robots.
		-- If the target is defeated by this quickhack,they burst into flames, cuasing enemies within a 6-meter radius to panic.
		{ id = "BrainMeltLvl3Program" }, 

		-- SYNAPSE BURNOUT / Quickhack / Legendary
		-- Deals Moderate damage that scales higher based on how much health the target is missing.
		-- Less effective against drones, mech and robots.
		-- If the target is defeated by this quickhack,they burst into flames, cuasing enemies within a 6-meter radius to panic.
		-- Passive While Equiped: Defeating an enemy with any quickhack causes nearby enemies to panic.
		{ id = "BrainMeltLvl4Program" }, 

		-- SYSTEM RESET / Quickhack / Epic
		-- Cripples a target's nervous system, causing them to lose consciousness.
		-- The affected target will not make any noise when passing out.
		{ id = "SystemCollapseLvl3Program" }, 

		-- SYSTEM RESET / Quickhack / Legendary
		-- Cripples a target's nervous system, causing them to lose consciousness.
		-- The affected target will not make any noise when passing out.
		-- Passive while equipped: defeating an enemy reduces the RAM cost of the next quickhack.
		{ id = "SystemCollapseLvl4Program" }, 

		-- WEAPON GLITCH / Quickhack / Uncommon
		-- Causes the target's weapon to malfunction, reducing its accuracy and disabling Smart tracking and obstavle penetration.
		{ id = "WeaponMalfunctionProgram" }, 

		-- WEAPON GLITCH / Quickhack / Rare
		-- Causes the target's weapon to malfunction, reducing its accuracy and disabling Smart tracking and obstavle penetration.
		-- Spreads to the nearest target within a radius.
		{ id = "WeaponMalfunctionLvl2Program" }, 

		-- WEAPON GLITCH / Quickhack / Epic
		-- Causes the target's weapon to malfunction, reducing its accuracy and disabling Smart tracking and obstavle penetration.
		-- Spreads to the nearest target within a radius.
		-- Causes the target's weapon to explode, causing damage.
		{ id = "WeaponMalfunctionLvl3Program" }, 

		-- WEAPON GLITCH / Quickhack / Legendary
		-- Causes the target's weapon to malfunction, reducing its accuracy and disabling Smart tracking and obstavle penetration.
		-- Spreads to the nearest target within a radius.
		-- Causes the target's weapon to explode, causing damage.
		-- Passive while equipped: enables the Weapons Jammer deamon during Breach Protocol.
		{ id = "WeaponMalfunctionLvl4Program" }, 

		-- WHISTLE / Quickhack / Uncommon
		-- The affected target will enter a heightened state of alertness and move to your current position.
		{ id = "WhistleProgram" }, 

		-- WHISTLE / Quickhack / Rare
		-- The target will no longer be in a state of alertness when moving to your current position.
		{ id = "WhistleLvl2Program" }, 

		-- WHISTLE / Quickhack / Epic
		-- The target will no longer be in a state of alertness when moving to your current position.
		-- Can be executed on enemies engaged in combat.
		{ id = "WhistleLvl3Program" }, 
	},
}