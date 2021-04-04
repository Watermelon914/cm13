/* * * * * * * * * * * * * * * * * * * * * * * * * *
 * /datum/recipe by rastaf0            13 apr 2011 *
 * * * * * * * * * * * * * * * * * * * * * * * * * *
 * This is powerful and flexible recipe system.
 * It exists not only for food.
 * supports both reagents and objects as prerequisites.
 * In order to use this system you have to define a deriative from /datum/recipe
 * * reagents are reagents. Acid, milc, booze, etc.
 * * items are objects. Fruits, tools, circuit boards.
 * * result is type to create as new object
 * * time is optional parameter, you shall use in in your machine,
     default /datum/recipe/ procs does not rely on this parameter.
 *
 *  Functions you need:
 *  /datum/recipe/proc/make(var/obj/container as obj)
 *    Creates result inside container,
 *    deletes prerequisite reagents,
 *    transfers reagents from prerequisite objects,
 *    deletes all prerequisite objects (even not needed for recipe at the moment).
 *
 *  /proc/select_recipe(list/datum/recipe/avaiable_recipes, obj/obj as obj, exact = 1)
 *    Wonderful function that select suitable recipe for you.
 *    obj is a machine (or magik hat) with prerequisites,
 *    exact = 0 forces algorithm to ignore superfluous stuff.
 *
 *
 *  Functions you do not need to call directly but could:
 *  /datum/recipe/proc/check_reagents(var/datum/reagents/avail_reagents)
 *    //1=precisely,  0=insufficiently, -1=superfluous
 *
 *  /datum/recipe/proc/check_items(var/obj/container as obj)
 *    //1=precisely, 0=insufficiently, -1=superfluous
 *
 * */

/datum/recipe
	var/list/reagents // example:  = list("berryjuice" = 5) // do not list same reagent twice
	var/list/items // example: =list(/obj/item/tool/crowbar, /obj/item/welder) // place /foo/bar before /foo
	var/result //example: = /obj/item/reagent_container/food/snacks/donut/normal
	var/time = 100 // 1/10 part of second


/datum/recipe/proc/check_reagents(var/datum/reagents/avail_reagents) //1=precisely, 0=insufficiently, -1=superfluous
	. = 1
	for (var/r_r in reagents)
		var/aval_r_amnt = avail_reagents.get_reagent_amount(r_r)
		if (!(abs(aval_r_amnt - reagents[r_r])<0.5)) //if NOT equals
			if (aval_r_amnt>reagents[r_r])
				. = -1
			else
				return 0
	if ((reagents?(reagents.len):(0)) < avail_reagents.reagent_list.len)
		return -1
	return .

/datum/recipe/proc/check_items(var/obj/container as obj) //1=precisely, 0=insufficiently, -1=superfluous
	if (!items)
		if (locate(/obj/) in container)
			return -1
		else
			return 1
	. = 1
	var/list/checklist = items.Copy()
	for (var/obj/O in container)
		var/found = 0
		for (var/type in checklist)
			if (istype(O,type))
				checklist-=type
				found = 1
				break
		if (!found)
			. = -1
	if (checklist.len)
		return 0
	return .

//general version
/datum/recipe/proc/make(var/obj/container as obj)
	var/obj/result_obj = new result(container)
	for (var/obj/O in (container.contents-result_obj))
		O.reagents.trans_to(result_obj, O.reagents.total_volume)
		qdel(O)
	container.reagents.clear_reagents()
	return result_obj

// food-related
/datum/recipe/proc/make_food(var/obj/container as obj)
	var/obj/result_obj = new result(container)
	for (var/obj/O in (container.contents-result_obj))
		if (O.reagents)
			O.reagents.del_reagent("nutriment")
			O.reagents.update_total()
			O.reagents.trans_to(result_obj, O.reagents.total_volume)
		qdel(O)
	container.reagents.clear_reagents()
	return result_obj

/proc/select_recipe(var/list/datum/recipe/avaiable_recipes, var/obj/obj as obj, var/exact = 1 as num)
	if (!exact)
		exact = -1
	var/list/datum/recipe/possible_recipes = new
	for (var/datum/recipe/recipe in avaiable_recipes)
		if (recipe.check_reagents(obj.reagents)==exact && recipe.check_items(obj)==exact)
			possible_recipes+=recipe
	if (possible_recipes.len==0)
		return null
	else if (possible_recipes.len==1)
		return possible_recipes[1]
	else //okay, let's select the most complicated recipe
		var/r_count = 0
		var/i_count = 0
		. = possible_recipes[1]
		for (var/datum/recipe/recipe in possible_recipes)
			var/N_i = (recipe.items)?(recipe.items.len):0
			var/N_r = (recipe.reagents)?(recipe.reagents.len):0
			if (N_i > i_count || (N_i== i_count && N_r > r_count ))
				r_count = N_r
				i_count = N_i
				. = recipe
		return .


/datum/recipe/friedegg
	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/egg
	)
	result = /obj/item/reagent_container/food/snacks/friedegg

/datum/recipe/boiledegg
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/egg
	)
	result = /obj/item/reagent_container/food/snacks/boiledegg

/datum/recipe/jellydonut
	reagents = list("berryjuice" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/donut/jelly

/datum/recipe/jellydonut/cherry
	reagents = list("cherryjelly" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/donut/cherryjelly

/datum/recipe/donut
	reagents = list("sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/donut/normal

/datum/recipe/human/burger
	items = list(
		/obj/item/reagent_container/food/snacks/meat/human,
		/obj/item/reagent_container/food/snacks/bun
	)
	result = /obj/item/reagent_container/food/snacks/human/burger

/datum/recipe/plainburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/meat //do not place this recipe before /datum/recipe/humanburger
	)
	result = /obj/item/reagent_container/food/snacks/monkeyburger

/datum/recipe/syntiburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh
	)
	result = /obj/item/reagent_container/food/snacks/monkeyburger

/datum/recipe/brainburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/organ/brain
	)
	result = /obj/item/reagent_container/food/snacks/brainburger

/datum/recipe/roburger
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/fake_robot_head
	)
	result = /obj/item/reagent_container/food/snacks/roburger

/datum/recipe/roburger_unsafe
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/robot_parts/head
	)
	result = /obj/item/reagent_container/food/snacks/roburger/unsafe

/datum/recipe/xenoburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/xenomeat
	)
	result = /obj/item/reagent_container/food/snacks/xenoburger

/datum/recipe/fishburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/carpmeat
	)
	result = /obj/item/reagent_container/food/snacks/fishburger

/datum/recipe/tofuburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/tofu
	)
	result = /obj/item/reagent_container/food/snacks/tofuburger


/datum/recipe/clownburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/clothing/mask/gas/clown_hat,
		/* /obj/item/reagent_container/food/snacks/grown/banana, */
	)
	result = /obj/item/reagent_container/food/snacks/clownburger

/datum/recipe/mimeburger
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/clothing/head/beret
	)
	result = /obj/item/reagent_container/food/snacks/mimeburger

/datum/recipe/hotdog
	items = list(
		/obj/item/reagent_container/food/snacks/bun,
		/obj/item/reagent_container/food/snacks/sausage
	)
	result = /obj/item/reagent_container/food/snacks/hotdog

/datum/recipe/waffles
	reagents = list("sugar" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/waffles

/datum/recipe/donkpocket
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meatball
	)
	result = /obj/item/reagent_container/food/snacks/donkpocket //SPECIAL
	proc/warm_up(var/obj/item/reagent_container/food/snacks/donkpocket/being_cooked)
		being_cooked.warm = 1
		being_cooked.reagents.add_reagent("tricordrazine", 5)
		being_cooked.bitesize = 6
		being_cooked.name = "Warm " + being_cooked.name
		being_cooked.cooltime()
	make_food(var/obj/container as obj)
		var/obj/item/reagent_container/food/snacks/donkpocket/being_cooked = ..(container)
		warm_up(being_cooked)
		return being_cooked

/datum/recipe/donkpocket/warm
	reagents = list() //This is necessary since this is a child object of the above recipe and we don't want donk pockets to need flour
	items = list(
		/obj/item/reagent_container/food/snacks/donkpocket
	)
	result = /obj/item/reagent_container/food/snacks/donkpocket //SPECIAL
	make_food(var/obj/container as obj)
		var/obj/item/reagent_container/food/snacks/donkpocket/being_cooked = locate() in container
		if(being_cooked && !being_cooked.warm)
			warm_up(being_cooked)
		return being_cooked

/datum/recipe/meatbread
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/meatbread

/datum/recipe/syntibread
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/meatbread

/datum/recipe/xenomeatbread
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/xenomeat,
		/obj/item/reagent_container/food/snacks/xenomeat,
		/obj/item/reagent_container/food/snacks/xenomeat,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/xenomeatbread

/datum/recipe/bananabread
	reagents = list("milk" = 5, "sugar" = 15)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/grown/banana,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/bananabread

/datum/recipe/omelette
	items = list(
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/omelette

/datum/recipe/muffin
	reagents = list("milk" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
	)
	result = /obj/item/reagent_container/food/snacks/muffin

/datum/recipe/eggplantparm
	items = list(
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/eggplant
	)
	result = /obj/item/reagent_container/food/snacks/eggplantparm

/datum/recipe/soylenviridians
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/grown/soybeans
	)
	result = /obj/item/reagent_container/food/snacks/soylenviridians

/datum/recipe/soylentgreen
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/meat/human,
		/obj/item/reagent_container/food/snacks/meat/human,
	)
	result = /obj/item/reagent_container/food/snacks/soylentgreen

/datum/recipe/carrotcake
	reagents = list("milk" = 5, "sugar" = 15)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/carrot,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/carrotcake

/datum/recipe/cheesecake
	reagents = list("milk" = 5, "sugar" = 15)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/cheesecake

/datum/recipe/plaincake
	reagents = list("milk" = 5, "sugar" = 15)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/plaincake

/datum/recipe/meatpie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/meat,
	)
	result = /obj/item/reagent_container/food/snacks/meatpie

/datum/recipe/tofupie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/tofu,
	)
	result = /obj/item/reagent_container/food/snacks/tofupie

/datum/recipe/xemeatpie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/xenomeat,
	)
	result = /obj/item/reagent_container/food/snacks/xemeatpie

/datum/recipe/pie
	reagents = list("sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/banana,
	)
	result = /obj/item/reagent_container/food/snacks/pie

/datum/recipe/cherrypie
	reagents = list("sugar" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/cherries,
	)
	result = /obj/item/reagent_container/food/snacks/cherrypie

/datum/recipe/berryclafoutis
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/berries,
	)
	result = /obj/item/reagent_container/food/snacks/berryclafoutis

/datum/recipe/wingfangchu
	reagents = list("soysauce" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/xenomeat,
	)
	result = /obj/item/reagent_container/food/snacks/wingfangchu

/datum/recipe/chaosdonut
	reagents = list("frostoil" = 5, "capsaicin" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/donut/chaos

/datum/recipe/human/kabob
	items = list(
		/obj/item/stack/rods,
		/obj/item/reagent_container/food/snacks/meat/human,
		/obj/item/reagent_container/food/snacks/meat/human,
	)
	result = /obj/item/reagent_container/food/snacks/human/kabob

/datum/recipe/monkeykabob
	items = list(
		/obj/item/stack/rods,
		/obj/item/reagent_container/food/snacks/meat/monkey,
		/obj/item/reagent_container/food/snacks/meat/monkey,
	)
	result = /obj/item/reagent_container/food/snacks/monkeykabob

/datum/recipe/syntikabob
	items = list(
		/obj/item/stack/rods,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
	)
	result = /obj/item/reagent_container/food/snacks/monkeykabob

/datum/recipe/tofukabob
	items = list(
		/obj/item/stack/rods,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/tofu,
	)
	result = /obj/item/reagent_container/food/snacks/tofukabob

/datum/recipe/tofubread
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/tofubread

/datum/recipe/loadedbakedpotato
	items = list(
		/obj/item/reagent_container/food/snacks/grown/potato,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/loadedbakedpotato

/datum/recipe/cheesyfries
	items = list(
		/obj/item/reagent_container/food/snacks/fries,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/cheesyfries

/datum/recipe/cubancarp
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)
	result = /obj/item/reagent_container/food/snacks/cubancarp

/datum/recipe/popcorn
	items = list(
		/obj/item/reagent_container/food/snacks/grown/corn
	)
	result = /obj/item/reagent_container/food/snacks/popcorn


/datum/recipe/cookie
	reagents = list("milk" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/chocolatebar,
	)
	result = /obj/item/reagent_container/food/snacks/cookie

/datum/recipe/fortunecookie
	reagents = list("sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/doughslice,
		/obj/item/paper,
	)
	result = /obj/item/reagent_container/food/snacks/fortunecookie
	make_food(var/obj/container as obj)
		var/obj/item/paper/paper = locate() in container
		paper.moveToNullspace() //prevent deletion
		var/obj/item/reagent_container/food/snacks/fortunecookie/being_cooked = ..(container)
		paper.forceMove(being_cooked)
		being_cooked.trash = paper //so the paper is left behind as trash without special-snowflake(TM Nodrak) code ~carn
		return being_cooked
	check_items(var/obj/container as obj)
		. = ..()
		if (.)
			var/obj/item/paper/paper = locate() in container
			if (!paper.info)
				return 0
		return .

/datum/recipe/meatsteak
	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/meat
	)
	result = /obj/item/reagent_container/food/snacks/meatsteak

/datum/recipe/syntisteak
	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/meat/syntiflesh
	)
	result = /obj/item/reagent_container/food/snacks/meatsteak

/datum/recipe/pizzamargherita
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/margherita

/datum/recipe/meatpizza
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/meatpizza

/datum/recipe/syntipizza
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/meat/syntiflesh,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/meatpizza

/datum/recipe/mushroompizza
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/mushroompizza

/datum/recipe/vegetablepizza
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/eggplant,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/corn,
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pizza/vegetablepizza

/datum/recipe/spacylibertyduff
	reagents = list("water" = 5, "vodka" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/mushroom/libertycap,
		/obj/item/reagent_container/food/snacks/grown/mushroom/libertycap,
		/obj/item/reagent_container/food/snacks/grown/mushroom/libertycap,
	)
	result = /obj/item/reagent_container/food/snacks/spacylibertyduff

/datum/recipe/amanitajelly
	reagents = list("water" = 5, "vodka" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
	)
	result = /obj/item/reagent_container/food/snacks/amanitajelly
	make_food(var/obj/container as obj)
		var/obj/item/reagent_container/food/snacks/amanitajelly/being_cooked = ..(container)
		being_cooked.reagents.del_reagent("amatoxin")
		return being_cooked

/datum/recipe/meatballsoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/meatball ,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/potato,
	)
	result = /obj/item/reagent_container/food/snacks/meatballsoup

/datum/recipe/vegetablesoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/corn,
		/obj/item/reagent_container/food/snacks/grown/eggplant,
		/obj/item/reagent_container/food/snacks/grown/potato,
	)
	result = /obj/item/reagent_container/food/snacks/vegetablesoup

/datum/recipe/nettlesoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/grown/nettle,
		/obj/item/reagent_container/food/snacks/grown/potato,
		/obj/item/reagent_container/food/snacks/egg,
	)
	result = /obj/item/reagent_container/food/snacks/nettlesoup

/datum/recipe/wishsoup
	reagents = list("water" = 20)
	result= /obj/item/reagent_container/food/snacks/wishsoup

/datum/recipe/hotchili
	items = list(
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/hotchili

/datum/recipe/coldchili
	items = list(
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/grown/icepepper,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/coldchili

/datum/recipe/amanita_pie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/mushroom/amanita,
	)
	result = /obj/item/reagent_container/food/snacks/amanita_pie

/datum/recipe/plump_pie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/mushroom/plumphelmet,
	)
	result = /obj/item/reagent_container/food/snacks/plump_pie

/datum/recipe/bigbiteburger
	items = list(
		/obj/item/reagent_container/food/snacks/monkeyburger,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/egg,
	)
	result = /obj/item/reagent_container/food/snacks/bigbiteburger

/datum/recipe/enchiladas
	items = list(
		/obj/item/reagent_container/food/snacks/cutlet,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/grown/chili,
		/obj/item/reagent_container/food/snacks/grown/corn,
	)
	result = /obj/item/reagent_container/food/snacks/enchiladas

/datum/recipe/creamcheesebread
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/creamcheesebread

/datum/recipe/monkeysdelight
	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/monkeycube,
		/obj/item/reagent_container/food/snacks/grown/banana,
	)
	result = /obj/item/reagent_container/food/snacks/monkeysdelight

/datum/recipe/baguette
	reagents = list("sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
	)
	result = /obj/item/reagent_container/food/snacks/baguette

/datum/recipe/fishandchips
	items = list(
		/obj/item/reagent_container/food/snacks/fries,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)
	result = /obj/item/reagent_container/food/snacks/fishandchips

/datum/recipe/birthdaycake
	reagents = list("milk" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/clothing/head/cakehat
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/birthdaycake

/datum/recipe/bread
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/egg
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/bread

/datum/recipe/sandwich
	items = list(
		/obj/item/reagent_container/food/snacks/meatsteak,
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/sandwich

/datum/recipe/toastedsandwich
	items = list(
		/obj/item/reagent_container/food/snacks/sandwich
	)
	result = /obj/item/reagent_container/food/snacks/toastedsandwich

/datum/recipe/grilledcheese
	items = list(
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/grilledcheese

/datum/recipe/tomatosoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/tomatosoup

/datum/recipe/rofflewaffles
	reagents = list("psilocybin" = 5, "sugar" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
	)
	result = /obj/item/reagent_container/food/snacks/rofflewaffles

/datum/recipe/stew
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/grown/potato,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/eggplant,
		/obj/item/reagent_container/food/snacks/grown/mushroom,
	)
	result = /obj/item/reagent_container/food/snacks/stew

/datum/recipe/jelliedtoast
	reagents = list("cherryjelly" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/breadslice,
	)
	result = /obj/item/reagent_container/food/snacks/jelliedtoast/cherry

/datum/recipe/milosoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/soydope,
		/obj/item/reagent_container/food/snacks/soydope,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/tofu,
	)
	result = /obj/item/reagent_container/food/snacks/milosoup

/datum/recipe/stewedsoymeat
	items = list(
		/obj/item/reagent_container/food/snacks/soydope,
		/obj/item/reagent_container/food/snacks/soydope,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/stewedsoymeat

/*/datum/recipe/spagetti We have the processor now
	items = list(
		/obj/item/reagent_container/food/snacks/doughslice
	)
	result= /obj/item/reagent_container/food/snacks/spagetti*/

/datum/recipe/boiledspagetti
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/spagetti,
	)
	result = /obj/item/reagent_container/food/snacks/boiledspagetti

/datum/recipe/boiledrice
	reagents = list("water" = 5, "rice" = 10)
	result = /obj/item/reagent_container/food/snacks/boiledrice

/datum/recipe/ricepudding
	reagents = list("milk" = 5, "rice" = 10)
	result = /obj/item/reagent_container/food/snacks/ricepudding

/datum/recipe/pastatomato
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/spagetti,
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/grown/tomato,
	)
	result = /obj/item/reagent_container/food/snacks/pastatomato

/datum/recipe/poppypretzel
	items = list(
		/obj/item/seeds/poppyseed,
		/obj/item/reagent_container/food/snacks/dough,
	)
	result = /obj/item/reagent_container/food/snacks/poppypretzel

/datum/recipe/meatballspagetti
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/spagetti,
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/meatball,
	)
	result = /obj/item/reagent_container/food/snacks/meatballspagetti

/datum/recipe/spesslaw
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/spagetti,
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/meatball,
	)
	result = /obj/item/reagent_container/food/snacks/spesslaw

/datum/recipe/superbiteburger
	reagents = list("sodiumchloride" = 5, "blackpepper" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/bigbiteburger,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/meat,
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/cheesewedge,
		/obj/item/reagent_container/food/snacks/boiledegg,
	)
	result = /obj/item/reagent_container/food/snacks/superbiteburger

/datum/recipe/candiedapple
	reagents = list("water" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/apple
	)
	result = /obj/item/reagent_container/food/snacks/candiedapple

/datum/recipe/applepie
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough,
		/obj/item/reagent_container/food/snacks/grown/apple,
	)
	result = /obj/item/reagent_container/food/snacks/applepie

/datum/recipe/applecake
	reagents = list("milk" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/dough,
		/obj/item/reagent_container/food/snacks/grown/apple,
		/obj/item/reagent_container/food/snacks/grown/apple,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/applecake

/datum/recipe/jellyburger
	reagents = list("cherryjelly" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/bun
	)
	result = /obj/item/reagent_container/food/snacks/jellyburger/cherry

/datum/recipe/twobread
	reagents = list("wine" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/breadslice,
	)
	result = /obj/item/reagent_container/food/snacks/twobread

/datum/recipe/cherrysandwich
	reagents = list("cherryjelly" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/breadslice,
		/obj/item/reagent_container/food/snacks/breadslice,
	)
	result = /obj/item/reagent_container/food/snacks/jellysandwich/cherry

/datum/recipe/orangecake
	reagents = list("milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/orange,
		/obj/item/reagent_container/food/snacks/grown/orange,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/orangecake

/datum/recipe/limecake
	reagents = list("milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/lime,
		/obj/item/reagent_container/food/snacks/grown/lime,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/limecake

/datum/recipe/lemoncake
	reagents = list("milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/lemon,
		/obj/item/reagent_container/food/snacks/grown/lemon,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/lemoncake

/datum/recipe/chocolatecake
	reagents = list("milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/chocolatebar,
		/obj/item/reagent_container/food/snacks/chocolatebar,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/chocolatecake

/datum/recipe/bloodsoup
	reagents = list("blood" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/bloodtomato,
		/obj/item/reagent_container/food/snacks/grown/bloodtomato,
	)
	result = /obj/item/reagent_container/food/snacks/bloodsoup

/datum/recipe/braincake
	reagents = list("milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/organ/brain
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/braincake

/datum/recipe/chocolateegg
	items = list(
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/chocolatebar,
	)
	result = /obj/item/reagent_container/food/snacks/chocolateegg

/datum/recipe/sausage
	items = list(
		/obj/item/reagent_container/food/snacks/meatball,
		/obj/item/reagent_container/food/snacks/cutlet,
	)
	result = /obj/item/reagent_container/food/snacks/sausage

/datum/recipe/fishfingers
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/carpmeat,
	)
	result = /obj/item/reagent_container/food/snacks/fishfingers

/datum/recipe/mysterysoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/badrecipe,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/cheesewedge,
	)
	result = /obj/item/reagent_container/food/snacks/mysterysoup

/datum/recipe/pumpkinpie
	reagents = list("milk" = 5, "sugar" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/grown/pumpkin,
		/obj/item/reagent_container/food/snacks/egg,
	)
	result = /obj/item/reagent_container/food/snacks/sliceable/pumpkinpie

/datum/recipe/plumphelmetbiscuit
	reagents = list("water" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/grown/mushroom/plumphelmet,
	)
	result = /obj/item/reagent_container/food/snacks/plumphelmetbiscuit

/datum/recipe/mushroomsoup
	reagents = list("water" = 5, "milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/mushroom/chanterelle,
	)
	result = /obj/item/reagent_container/food/snacks/mushroomsoup

/datum/recipe/chawanmushi
	reagents = list("water" = 5, "soysauce" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/mushroom/chanterelle,
	)
	result = /obj/item/reagent_container/food/snacks/chawanmushi

/datum/recipe/beetsoup
	reagents = list("water" = 10)
	items = list(
		/obj/item/reagent_container/food/snacks/grown/whitebeet,
		/obj/item/reagent_container/food/snacks/grown/cabbage,
	)
	result = /obj/item/reagent_container/food/snacks/beetsoup

/datum/recipe/appletart
	reagents = list("sugar" = 5, "milk" = 5)
	items = list(
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/flour,
		/obj/item/reagent_container/food/snacks/egg,
		/obj/item/reagent_container/food/snacks/grown/goldapple,
	)
	result = /obj/item/reagent_container/food/snacks/appletart

/datum/recipe/tossedsalad
	items = list(
		/obj/item/reagent_container/food/snacks/grown/cabbage,
		/obj/item/reagent_container/food/snacks/grown/cabbage,
		/obj/item/reagent_container/food/snacks/grown/tomato,
		/obj/item/reagent_container/food/snacks/grown/carrot,
		/obj/item/reagent_container/food/snacks/grown/apple,
	)
	result = /obj/item/reagent_container/food/snacks/tossedsalad

/datum/recipe/aesirsalad
	items = list(
		/obj/item/reagent_container/food/snacks/grown/ambrosiadeus,
		/obj/item/reagent_container/food/snacks/grown/ambrosiadeus,
		/obj/item/reagent_container/food/snacks/grown/ambrosiadeus,
		/obj/item/reagent_container/food/snacks/grown/goldapple,
	)
	result = /obj/item/reagent_container/food/snacks/aesirsalad

/datum/recipe/validsalad
	items = list(
		/obj/item/reagent_container/food/snacks/grown/ambrosiavulgaris,
		/obj/item/reagent_container/food/snacks/grown/ambrosiavulgaris,
		/obj/item/reagent_container/food/snacks/grown/ambrosiavulgaris,
		/obj/item/reagent_container/food/snacks/grown/potato,
		/obj/item/reagent_container/food/snacks/meatball,
	)
	result = /obj/item/reagent_container/food/snacks/validsalad
	make_food(var/obj/container as obj)
		var/obj/item/reagent_container/food/snacks/validsalad/being_cooked = ..(container)
		being_cooked.reagents.del_reagent("toxin")
		return being_cooked

/datum/recipe/cracker
	reagents = list("sodiumchloride" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/doughslice
	)
	result = /obj/item/reagent_container/food/snacks/cracker

/datum/recipe/stuffing
	reagents = list("water" = 5, "sodiumchloride" = 1, "blackpepper" = 1)
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/bread,
	)
	result = /obj/item/reagent_container/food/snacks/stuffing

/datum/recipe/tofurkey
	items = list(
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/tofu,
		/obj/item/reagent_container/food/snacks/stuffing,
	)
	result = /obj/item/reagent_container/food/snacks/tofurkey

//////////////////////////////////////////
// bs12 food port stuff
//////////////////////////////////////////

/datum/recipe/taco
	items = list(
		/obj/item/reagent_container/food/snacks/doughslice,
		/obj/item/reagent_container/food/snacks/cutlet,
		/obj/item/reagent_container/food/snacks/cheesewedge
	)
	result = /obj/item/reagent_container/food/snacks/taco

/datum/recipe/bun
	items = list(
		/obj/item/reagent_container/food/snacks/dough
	)
	result = /obj/item/reagent_container/food/snacks/bun

/datum/recipe/flatbread
	items = list(
		/obj/item/reagent_container/food/snacks/sliceable/flatdough
	)
	result = /obj/item/reagent_container/food/snacks/flatbread

/datum/recipe/meatball
	items = list(
		/obj/item/reagent_container/food/snacks/rawmeatball
	)
	result = /obj/item/reagent_container/food/snacks/meatball

/datum/recipe/cutlet
	items = list(
		/obj/item/reagent_container/food/snacks/rawcutlet
	)
	result = /obj/item/reagent_container/food/snacks/cutlet

/datum/recipe/fries
	items = list(
		/obj/item/reagent_container/food/snacks/rawsticks
	)
	result = /obj/item/reagent_container/food/snacks/fries

/datum/recipe/mint
	reagents = list("sugar" = 5, "frostoil" = 5)
	result = /obj/item/reagent_container/food/snacks/mint
