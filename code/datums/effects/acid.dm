/datum/effects/acid
	effect_name = "acid"
	duration = 20
	icon_path = 'icons/effects/status_effects.dmi'
	obj_icon_state_path = "+acid"
	mob_icon_state_path = "human_acid"
	var/original_duration = 50			//Set to 50 for safety reasons if something fails
	var/damage_in_total = 50

/datum/effects/acid/New(var/atom/A, var/zone = "chest")
	..()
	if(isHumanStrict(A))
		var/mob/living/carbon/human/H = A
		H.update_effects()

	if(isobj(A))
		var/obj/O = A
		O.update_icon()

	original_duration = duration

/datum/effects/acid/validate_atom(var/atom/A)
	if(istype(A, /obj/structure/barricade))
		return TRUE

	if(isobj(A))
		return FALSE

	if(ishuman(A))
		var/mob/living/carbon/human/H = A
		if(H.status_flags & XENO_HOST && istype(H.buckled, /obj/structure/bed/nest) || H.stat == DEAD)
			return FALSE

	. = ..()

/datum/effects/acid/process_mob()
	. = ..()
	if(!.)
		return FALSE

	var/mob/living/carbon/affected_mob = affected_atom
	affected_mob.last_damage_source = source
	affected_mob.last_damage_mob = source_mob
	affected_mob.apply_damage(damage_in_total/original_duration, BURN, def_zone)

	return TRUE

/datum/effects/acid/process_obj()
	. = ..()
	if(!.)
		return FALSE

	var/obj/affected_obj = affected_atom
	affected_obj.update_health(damage_in_total/original_duration)
	
	return TRUE

/datum/effects/acid/Dispose()
	if(affected_atom)
		affected_atom.effects_list -= src
	
	if(isHumanStrict(affected_atom))
		var/mob/living/carbon/human/H = affected_atom
		H.update_effects()

	if(isobj(affected_atom))
		var/obj/O = affected_atom
		O.update_icon()
	..()