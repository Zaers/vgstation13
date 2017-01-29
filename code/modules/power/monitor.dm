#define POWER_MONITOR_HIST_SIZE 15

// the power monitoring computer
// for the moment, just report the status of all APCs in the same powernet
/obj/machinery/power/monitor
	name = "Power Monitoring Computer"
	desc = "It monitors power levels across the station."
	icon = 'icons/obj/computer.dmi'
	icon_state = "power"

	use_auto_lights = 1
	light_range_on = 3
	light_power_on = 1
	light_color = LIGHT_COLOR_YELLOW

	//computer stuff
	density = 1
	anchored = 1.0
	var/circuit = /obj/item/weapon/circuitboard/powermonitor
	use_power = 1
	idle_power_usage = 300
	active_power_usage = 300



/obj/machinery/power/monitor/New()
	..()

	var/obj/structure/cable/attached = null
	var/turf/T = loc
	if(isturf(T))
		attached = locate() in T
	if(attached)
		powernet = attached.get_powernet()



/obj/machinery/power/monitor/attack_ai(mob/user)
	. = attack_hand(user)

/obj/machinery/power/monitor/Destroy()
	..()


/obj/machinery/power/monitor/attack_hand(mob/user)
	. = ..()

	ui_interact(user)


/obj/machinery/power/monitor/interact(mob/user)
	ui_interact(user)


/obj/machinery/power/monitor/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	if(stat & (BROKEN|NOPOWER))
		return
	user.set_machine(src)

	var/list/S = list(" <span class='bad'>Off","<span class='bad'>AOff","  <span class='good'>On", " <span class='good'>AOn")
	var/list/chg = list(" <span class='bad'>N</span>","<span class='average'>C</span>","<span class='good'>F</span>")

	var/data[0]
	var/list/APClist = list()

	data["connected"] = "[powernet ? 1 : 0]"
	data["totalPower"] = avail()
	data["totalLoad"] = num2text(powernet.viewload,10)
	data["totalDemand"] = load()

	for(var/obj/machinery/power/terminal/term in powernet.nodes)
		if(istype(term.master, /obj/machinery/power/apc))
			var/obj/machinery/power/apc/A = term.master
			var/APCData = list()
			APCData["areaName"] = A.areaMaster
			APCData["equipment"] = S[A.equipment+1]
			APCData["lighting"] = S[A.lighting+1]
			APCData["environment"] = S[A.lighting+1]
			APCData["powerUsed"] = A.lastused_total
			if(A.cell)
				var/class = "good"

				switch(A.cell.percent())
					if(49 to 15)
						class = "average"
					if(15 to -INFINITY)
						class = "bad"
				APCData["cellCharge"] ="<span class='[class]'>[round(A.cell.percent())]%</span> [chg[A.charging+1]]"
			else
				APCData["cellCharge"] = "<span class='bad'>N/C</span>"
			APClist += list(APCData) //lmao 2list

	data["APClist"] = APClist

	//ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui) // no ui has been passed, so we'll search for one
		ui = nanomanager.get_open_ui(user, src, ui_key)
	if(!ui)
		ui = new(user, src, ui_key, "power_monitor.tmpl", "Power Monitoring Computer", 640, 800)


		ui.set_initial_data(data)
		ui.open()

		// should make the UI auto-update; doesn't seem to?
		ui.set_auto_update(1)
	else
		// The UI is already open so push the new data to it
		ui.push_data(data)
		return


/obj/machinery/power/monitor/power_change()
	..()
	if(stat & BROKEN)
		icon_state = "broken"
	else
		if (stat & NOPOWER)
			spawn(rand(0, 15))
				src.icon_state = "c_unpowered"
		else
			icon_state = initial(icon_state)

//copied from computer.dm
/obj/machinery/power/monitor/attackby(I as obj, mob/user as mob)
	if(isscrewdriver(I) && circuit)
		playsound(src.loc, 'sound/items/Screwdriver.ogg', 50, 1)
		if(do_after(user,src,20))
			var/obj/structure/computerframe/A = new /obj/structure/computerframe( src.loc )
			var/obj/item/weapon/circuitboard/M = new circuit( A )
			A.circuit = M
			A.anchored = 1
			for (var/obj/C in src)
				C.forceMove(src.loc)
			if (src.stat & BROKEN)
				user.show_message("<span class=\"info\">The broken glass falls out.</span>")
				new /obj/item/weapon/shard( src.loc )
				A.state = 3
				A.icon_state = "3"
			else
				user.show_message("<span class=\"info\">You disconnect the monitor.</span>")
				A.state = 4
				A.icon_state = "4"

			qdel(src)
	else
		src.attack_hand(user)
	return

#undef POWER_MONITOR_HIST_SIZE