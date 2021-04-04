/obj/effect/alien/resin/special/nest
    name = XENO_STRUCTURE_NEST
    desc = "A very thick nest, oozing with a thick sticky substance."
    pixel_x = -8
    pixel_y = -8

    mouse_opacity = 1

    icon_state = "reinforced_nest"
    health = 400
    var/obj/structure/bed/nest/structure/pred_nest

    block_range = 2

/obj/effect/alien/resin/special/nest/examine(mob/user)
    ..()
    if((isXeno(user) || isobserver(user)) && linked_hive)
        var/message = "Used to secure formidable hosts."
        to_chat(user, message)

/obj/effect/alien/resin/special/nest/Initialize(mapload, datum/hive_status/hive_ref)
	. = ..()
	icon = get_icon_from_source(CONFIG_GET(string/alien_structures_48x48))
	var/hive = 0
	if(hive_ref)
		hive = hive_ref.hivenumber

	pred_nest = new /obj/structure/bed/nest/structure(loc, hive, src) // Nest cannot be destroyed unless the structure itself is destroyed

/obj/effect/alien/resin/special/nest/Destroy()
    . = ..()

    pred_nest?.linked_structure = null
    QDEL_NULL(pred_nest)
