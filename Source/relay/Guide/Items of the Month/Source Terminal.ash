void IOTMSourceTerminalGenerateDigitiseTargets(string [int] description)
{
    string [int] potential_targets;
    if (__quest_state["Level 7"].state_int["alcove evilness"] > 31)
        potential_targets.listAppend("modern zmobie");
    if (!__quest_state["Level 8"].state_boolean["Mountain climbed"] && $items[ninja rope,ninja carabiner,ninja crampons].available_amount() == 0 && !have_outfit_components("eXtreme Cold-Weather Gear"))
        potential_targets.listAppend("ninja assassin");
    if (!__quest_state["Level 12"].state_boolean["Lighthouse Finished"] && $item[barrel of gunpowder].available_amount() < 5)
        potential_targets.listAppend("lobsterfrogman");
    //FIXME witchess bishop or knight
    if (__iotms_usable[lookupItem("Witchess Set")] && get_property_int("_witchessFights") < 5)
    {
        string [int] witchess_list;
        if (__misc_state["can eat just about anything"])
            witchess_list.listAppend("knight");
        if (__misc_state["can drink just about anything"])
            witchess_list.listAppend("bishop");
        witchess_list.listAppend("rook");
        potential_targets.listAppend("witchess " + witchess_list.listJoinComponents("/"));
    }
    int desks_remaining = clampi(5 - get_property_int("writingDesksDefeated"), 0, 5);
    if (desks_remaining > 1 && !get_property_ascension("lastSecondFloorUnlock") && $item[Lady Spookyraven's necklace].available_amount() == 0 && get_property("questM20Necklace") != "finished" && mafiaIsPastRevision(15244))
        potential_targets.listAppend("writing desk");
    if (potential_targets.count() > 0)
        description.listAppend("Could target a " + potential_targets.listJoinComponents(", ", "or") + ".");
    if (get_property_int("_sourceTerminalDigitizeMonsterCount") >= 2)
        description.listAppend("Could re-digitise to reset the window.");
}

RegisterTaskGenerationFunction("IOTMSourceTerminalGenerateTasks");
void IOTMSourceTerminalGenerateTasks(ChecklistEntry [int] task_entries, ChecklistEntry [int] optional_task_entries, ChecklistEntry [int] future_task_entries)
{
    if (in_bad_moon() || get_campground()[lookupItem("Source Terminal")] == 0 || my_path_id() == PATH_ACTUALLY_ED_THE_UNDYING)
        return;
    if (!mafiaIsPastRevision(17011))
        return;
    ChecklistSubentry [int] subentries;
    
    boolean [string] chips = getInstalledSourceTerminalSingleChips();
    //Learn extract/a skill if we don't have one:
    boolean [skill] skills_have = getActiveSourceTerminalSkills();
    int skill_limit = 1;
    if (chips["DRAM"])
        skill_limit = 2;
    int skills_need = skill_limit - skills_have.count();
    if (skills_need > 0)
    {
        //FIXME this could be rewritten to suggest turbo + compress, when we have enough extractions.
        string [int] possible_skills;
        if (!skills_have[lookupSkill("Extract")])
            possible_skills.listAppend("Extract");
        if (!skills_have[lookupSkill("Turbo")])
            possible_skills.listAppend("Turbo");
        
        string linker = "or";
        if (skills_need > 1)
            linker = "and";
        subentries.listAppend(ChecklistSubentryMake("Learn " + pluralise(skills_need, "skill", "skills"), "", "Maybe " + possible_skills.listJoinComponents(", ", linker) + "."));
    }
    
    //Set an enquiry:
    if (get_property("sourceTerminalEnquiry") == "")
    {
        //familiar - +5 familiar weight
        //monsters - +25 ML (in-run)
        //protect - +3 all res (?)
        //stats - +all stats (in-run)
        string [int][int] enquiries;
        if (!__misc_state["familiars temporarily blocked"])
            enquiries.listAppend(listMake("familiar.enq", "+5 familiar weight"));
        if (__misc_state["in run"])
        {
            enquiries.listAppend(listMake("monsters.enq", "+25 ML"));
            enquiries.listAppend(listMake("stats.enq", "+100% stats"));
        }
        string [int] description;
        
        if (chips["DIAGRAM"] && get_property_int("sourceTerminalGram") >= 10)
            description.listAppend("200 turn buff gained at rollover.");
        else //gram chips are mysterious
            description.listAppend("Buff gained at rollover.");
        foreach key in enquiries
        {
            description.listAppend(enquiries[key][0] + ": " + enquiries[key][1]);
        }
        subentries.listAppend(ChecklistSubentryMake("Set an enquiry", "", description));
    }
    //"Digitise something" like arrow something?
    if (get_property_int("_sourceTerminalDigitizeUses") == 0 && __misc_state["in run"])
    {
        string [int] description;
        IOTMSourceTerminalGenerateDigitiseTargets(description);
        subentries.listAppend(ChecklistSubentryMake("Digitise a monster", "", description));
    }
    //Complicated, since we have three uses, and those are sort of resources...
    //Maybe suggest the first use, and always list in resources for the rest.
    //"Upgrade your source terminal" suggestions? Chips, essentially.
    
    if (subentries.count() > 0)
        optional_task_entries.listAppend(ChecklistEntryMake("__item source essence", "campground.php?action=terminal", subentries, 5));
}

RegisterResourceGenerationFunction("IOTMSourceTerminalGenerateResource");
void IOTMSourceTerminalGenerateResource(ChecklistEntry [int] resource_entries)
{
    if (in_bad_moon() || get_campground()[lookupItem("Source Terminal")] == 0 || my_path_id() == PATH_ACTUALLY_ED_THE_UNDYING)
        return;
    
    boolean [string] chips = getInstalledSourceTerminalSingleChips();
    //sourceTerminalChips, sourceTerminalPram, sourceTerminalGram, sourceTerminalSpam
    ChecklistSubentry [int] subentries;
    //Enhancement buffs:
    int enhancement_limit = 1;
    if (chips["CRAM"]) //CRAM chip installed
        enhancement_limit += 1;
    if (chips["SCRAM"]) //SCRAM chip installed
        enhancement_limit += 1;
    int enhancements_remaining = clampi(enhancement_limit - get_property_int("_sourceTerminalEnhanceUses"), 0, enhancement_limit);
    if (enhancements_remaining > 0 && mafiaIsPastRevision(17011))
    {
        int turn_duration = 25; //up to 100
        if (chips["INGRAM"])
            turn_duration += 25;
        turn_duration += get_property_int("sourceTerminalPram") * 5;
        turn_duration = clampi(turn_duration, 25, 100);
        string turns_description = " (" + turn_duration + " turns)";
        string [int] description;
        description.listAppend("items.enh: +30% item." + turns_description);
        description.listAppend("meat.enh: +60% meat." + turns_description);
        if (__misc_state["in run"])
            description.listAppend("init.enh: +50% init." + turns_description);
        //the others are moderately boring
        //+critical hit? niche
        //+all elemental damage? useful in two places, but still niche enough to not be put here
        //substats.enh is probably less than 150 mainstat. that's not a lot... +item is much more useful
        subentries.listAppend(ChecklistSubentryMake(pluralise(enhancements_remaining, "source enhancement", "source enhancements") + " remaining", "", description));
    }
    if (mafiaIsPastRevision(17031) && !get_property_boolean("_sourceTerminalDuplicateUsed") && __misc_state["in run"])
    {
        //Duplication of a monster:
        string [int] description;
        boolean [skill] skills_have = getActiveSourceTerminalSkills();
        
        string line = "Doubles";
        if (my_path_id() == PATH_THE_SOURCE)
            line = "Triples";
        line += " item drops from a monster, once/day.|Makes them stronger, so be careful.";
        description.listAppend(line);
        if (!skills_have[lookupSkill("Duplicate")])
        {
            description.listAppend("Learn with command \"educate duplicate.edu\".");
        }
        
        string [int] potential_targets;
        //FIXME grey out if the area isn't available?
        if ($item[goat cheese].available_amount() < 2 && !__quest_state["Level 8"].state_boolean["Past mine"])
            potential_targets.listAppend("diary goat");
        if (!__quest_state["Level 11"].finished && !__quest_state["Level 11 Palindome"].finished && $item[talisman o' namsilat].available_amount() == 0 && $items[gaudy key,snakehead charrrm].available_amount() < 2)
            potential_targets.listAppend("gaudy pirate");
        if (potential_targets.count() > 0)
            description.listAppend("Could use on a " + potential_targets.listJoinComponents(", ", "or") + ".");
        
        subentries.listAppend(ChecklistSubentryMake("Duplication usable", "", description));
    }
    //Portscans: (the source)
    int portscans_remaining = clampi(3 - get_property_int("_sourceTerminalPortscanUses"), 0, 3);
    if (mafiaIsPastRevision(17031) && portscans_remaining > 0 && my_path_id() == PATH_THE_SOURCE)
    {
        //Should we suggest portscan outside of the source?
        //It's three scaling monsters a day, that can make one government potion/run, if optimally used in delay-burning areas. Otherwise, they're +turncount for no reason.
        //So, do we give advice that's easy to get wrong?
        
        string [int] description;
        description.listAppend("Cast to summon an agent next turn. Make sure to use it to burn delay.");
        if (my_path_id() == PATH_THE_SOURCE)
            description.listAppend("To use optimally, cast once. Then set your autoattack to portscan, and adventure in a delay-burning area.|This will chain the agents, causing them to cost a single turn.");
        if (get_property_int("sourceInterval") != 0 && my_path_id() == PATH_THE_SOURCE)
            description.listAppend("Wait a bit, this is better after an agent had just appeared.");
        
        subentries.listAppend(ChecklistSubentryMake(pluralise(portscans_remaining, "portscan", "portscans") + " remaining", "", description));
        
    }
    //Extrudes:
    int extrudes_remaining = clampi(3 - get_property_int("_sourceTerminalExtrudes"), 0, 3);
    
    if (extrudes_remaining > 0 && mafiaIsPastRevision(16992))
    {
        int essence = lookupItem("source essence").available_amount();
        string [int] description;
        if (__misc_state["can eat just about anything"])
        {
            string line = "Food: 4 fullness epic.";
            if (essence < 10)
                line = HTMLGenerateSpanFont(line, "grey");
            description.listAppend(line);
        }
        if (__misc_state["can drink just about anything"])
        {
            string line = "Drink: 4 inebriety epic.";
            if (__misc_state["in run"])
                line += " Useful nightcap.";
            if (essence < 10)
                line = HTMLGenerateSpanFont(line, "grey");
            description.listAppend(line);
        }
        if (!__misc_state["in run"])
        {
            //In aftercore, suggest chips we don't have. Also the shades.
            if (lookupItem("source shades").available_amount() == 0 && essence >= 100)
                description.listAppend("Source Shades: extra essence extracted when equipped.");
            if (!lookupFamiliar("software bug").have_familiar() && essence >= 10000)
                description.listAppend("Software bug: pet rock.");
            string [int] chips_missing;
            foreach s in $strings[CRAM,DRAM,TRAM]
            {
                if (!chips[s])
                    chips_missing.listAppend(s);
            }
            if (get_property_int("sourceTerminalGram") < 10)
                chips_missing.listAppend("GRAM");
            if (get_property_int("sourceTerminalPram") < 10)
                chips_missing.listAppend("PRAM");
            if (get_property_int("sourceTerminalSpam") < 10)
                chips_missing.listAppend("SPAM");
            if (chips_missing.count() > 0)
                description.listAppend("Chip upgrades: " + chips_missing.listJoinComponents(", ", "or") + ".");
        }
        if (essence == 0 && __misc_state["in run"])
        {
            boolean have_extract_skill = true;
            if (!have_extract_skill)
                description.listAppend("Learn and use the extract skill in combat for more essence.");
            else
                description.listAppend("Use the extract skill in combat for more essence.");
        }
        
        subentries.listAppend(ChecklistSubentryMake(pluralise(extrudes_remaining, "source extrude", "source extrudes") + " remaining", "", description));
    }
    //Digitise?
    int digitisations = get_property_int("_sourceTerminalDigitizeUses");
    int digitisation_limit = 1;
    if (chips["TRAM"])
        digitisation_limit += 1;
    if (chips["TRIGRAM"])
        digitisation_limit += 1;
    int digitisations_left = clampi(digitisation_limit - digitisations, 0, 3);
    if (digitisations_left > 0)
    {
        string [int] description;
        string monster_name = get_property("_sourceTerminalDigitizeMonster").to_lower_case();
        if (monster_name != "")
            description.listAppend("Currently set to " + monster_name + ".");
        IOTMSourceTerminalGenerateDigitiseTargets(description);
        
        subentries.listAppend(ChecklistSubentryMake(pluralise(digitisations_left, "digitisation", "digitisations") + " remaining", "", description));
    }
    if (subentries.count() > 0)
        resource_entries.listAppend(ChecklistEntryMake("__item source essence", "campground.php?action=terminal", subentries, 5));
}