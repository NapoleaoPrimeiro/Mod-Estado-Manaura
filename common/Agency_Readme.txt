The Fight For The Fatherland Automatic Agency Upgrader (A.K.A The MossadBot-3000) has been designed to be a straightforward, highly changeable, easy to edit mod. This readme should contain all the information to quickly adapt it into your mod. If your mod keeps the vanilla agency system, you should be able to simply drop these files into your mod without issue. Regardless, it wouldn't hurt to understand how it works. That being said, let's begin.

We start with common/ideas/FFTF_agency_tokens_and_ideas.txt. This file contains the ideas we use to simulate civilian factory usage as well as token ideas. If you have no idea what token ideas are, all will be explained, but we'll start with the upgrade cost ideas.
These ideas are fairly simple - we add them when we start upgrading and remove them when we finish. Not too hard to understand. You could create a new variable that tracks the current upgrade's civilian factory usage and use that within a dynamic modifier to avoid hard-coding the ideas, however since variable using dynamic modifiers aren't as well optimised as static ideas (it's not massive, but every optimisation counts) and there's only four possible values for the upgrades to be, we might as well use ideas.

Next are the token ideas. For those of you who don't know, you can set a variable to be a token (https://hoi4.paradoxwikis.com/Data_structures#Token-valued_variables), and use "GetTokenKey" and "GetTokenLocalizedKey" to retrieve it's debug name and it's localised name respectively. Combined with meta effects (https://hoi4.paradoxwikis.com/Effect#Meta_effects), this essentially allows us to pass strings as variables in HoI4 - a very powerful feature for GUIs and allows for easier editing of code and avoids extremely long if-else sequences.
Each agency upgrade needs a token for it's game name, localised name and GFX name. They can be called whatever, but the present layout is recommended. 
In the localisation file, they should be localised as set out above.

The next important thing is the common/on_actions/FFTF_agency_on_actions.txt file. This is where we set up all of the information about the upgrades. We start by setting the variable "global.agency_upgrade_time_days_base" to the default upgrade time, in our case 30. This is used to calculate how long the upgrade mission runs for.
Next, we set up our arrays. For those of you with some level of programming knowledge, this is basically the HoI4 equivalent of creating an array of classes or structs, if we have our index we can search the necessary array for it's name, factory cost, and so on. Given our aforementioned ability to store strings as variables, being able to store an array of classes, made up of numbers, strings (and even arrays if you know what you're doing) opens up a lot of possibilities for exciting GUIs. All of the arrays in this section should be fairly self explanatory, so we'll move on to the effects at the bottom of the on actions file.
"global.agency_upgrade_icon_button_x" and "global.agency_upgrade_icon_button_y" define the x and y co-ordinates of our upgrades within the GUI (once again, fairly self explanatory).
We then define the array "agency_upgrades_completed_and_queued" for every country. This array tracks how many upgrades are currently either in the queue or have been completed via the auto-upgrader. Sadly, the game provides no way to track how many upgrades have been done manually, which allows for the player to select passive defence four times even if they've manually upgraded it thrice, for example.

That was a lot, so let's go over some simpler things for now, going to common/modifier_definitions/FFTF_agency_modifier_definitions.txt. Modifier definitions allows for mods to define custom modifiers, and since there's no "on_start" or "on_complete" arguments for intelligence upgrades, we use a boolean modifier to find out if we have an upgrade selected (You could create a modifier for each upgrade to find out which upgrades have been completed manually and fix the issue I mentioned earlier, but I left such a feature out of the mod).
Speaking of which, let's move on to common/intelligence_agency_upgrades/intelligence_agency_upgrades.txt. This is the only base game file present in the mod, but what I've done here isn't very complicated, and you can just modify your upgrade files if you've changed anything from vanilla. 
Every upgrade needs the following blocks of code:

modifiers_during_progress = {
	hidden_modifier = { FFTF_is_working_on_agency_upgrades_boolean = 1 }
}

available = {
	custom_trigger_tooltip = {
		tooltip = cannot_manually_upgrade_agency_tt
		
		NOT = { has_country_flag = spy_agency_upgrade_in_progress_flag }
	}
}

Both of which use booleans so that the player can't do two upgrades at once.

Next are common/scripted_effects/FFTF_agency_scripted_effects.txt and common/scripted_guis/FFTF_agency_queue_gui.txt, containing the meat and potatoes of the GUI's logic, but you shouldn't have to touch these unless you want to change the code's logic or add new features.

Now we move onto common/scripted_triggers/FFTF_agency_scripted_triggers.txt, which contains the only real hard coding outside of our idea and on actions files. Every upgrade needs a "FFTF_agency_can_select_upgrade_[ID]_trigger" equal to it's available argument in the upgrade file, and I'm not sure if you can put loops within a limit for the "can_upgrade_intelligence_agency" trigger. In that trigger, I've only put the can_select_[ID]_triggers in the ones I know are not false. You could perhaps create a new token idea, which localised to the upgrades's trigger ("has_done_agency_upgrade = upgrade_crypto_strength has_tech = mechanical_computing", "always = yes", etc.) and then use that within a meta trigger, but that just seems hacky and unnecessary.

Finally, common/decisions/FFTF_agency_upgrade_decisions.txt holds the mission that we use to count down to the upgrade once selected and inform the player of what the next upgrade is (you could use a hidden event and have this all in the GUI if you don't want to use a decision)(and yes, you can use variables for the days argument in a country_event). The only thing here is you could maybe use a meta effect instead of the if-else remove_ideas block, but as there's only four possibilities, there isn't really a need to code that.