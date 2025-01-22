program_name='Timeclocks'
(***********************************************************)
(*  FILE CREATED ON: 07/12/2022  AT: 15:20:55              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 02/13/2023  AT: 13:43:04        *)
(***********************************************************)
define_constant
	
	//-----------------------------------------------------------------------------
	// Identifiers ----------------------------------------------------------------
	//-----------------------------------------------------------------------------
	ID_TIMECLOCK_1			= 301
	ID_TIMECLOCK_2			= 302
	ID_TIMECLOCK_3			= 303
	ID_TIMECLOCK_4			= 304
	ID_TIMECLOCK_5			= 305
	
	//-----------------------------------------------------------------------------
	// Count ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	MAX_TIMECLOCKS			= 2
	
	//-----------------------------------------------------------------------------
	// Enumerators ----------------------------------------------------------------
	//-----------------------------------------------------------------------------
	
	DAY_MONDAY 				= 1
	DAY_TUESDAY				= 2
	DAY_WEDNESDAY			= 3
	DAY_THURSDAY			= 4
	DAY_FRIDAY				= 5
	DAY_SATURDAY			= 6
	DAY_SUNDAY				= 7
	
	MORNING					= 0
	EVENING					= 1
	
	
define_variable
	
	//-----------------------------------------------------------------------------
	// Timings --------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	constant long TIMING_THIRD_SECOND[1] 					= {300}			// 0,3s
	constant long TIMING_HALF_SECOND[1]						= {500}			// 0,5s
	constant long TIMING_ONE_SECOND[1] 						= {1000}		// 1s
	constant long TIMING_ONE_MINUTE[1] 						= {60000}		// 1m
	
	//-----------------------------------------------------------------------------
	// Timeclocks -----------------------------------------------------------------
	//-----------------------------------------------------------------------------
	persistent char timeclocks_morning[MAX_TIMECLOCKS][8]		= {'07:00:00', '07:00:00'}
	persistent char timeclocks_evening[MAX_TIMECLOCKS][8]		= {'19:30:00', '19:30:00'}
	persistent char timeclocks_enabled[MAX_TIMECLOCKS][2]		= {{false, false}, {false, false}}
	persistent sinteger timeclocks_days[MAX_TIMECLOCKS][7]		= {{1,1,1,1,1,0,0}, {1,1,1,1,1,0,0}}
	persistent sinteger timeclocks_duration[MAX_TIMECLOCKS][2] 	= {{3,3}, {3,3}} // {morning,evening}
	persistent integer force_start_btns[MAX_TIMECLOCKS]			= {0,0}
	volatile integer timeclocks_type[MAX_TIMECLOCKS]			= {MORNING,MORNING}
	volatile sinteger MAX_DURATION								= 8
	
	//-----------------------------------------------------------------------------
	// Channels -------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	constant integer i_ch_timeclock_1[20] 					= {901,902,903,904,905,906,907,908,909,910,911,912,913,914,915,916,917,918,919,920}
	constant integer i_ch_timeclock_2[20] 					= {921,922,923,924,925,926,927,928,929,930,931,932,933,934,935,936,937,938,939,940}
	constant integer i_ch_timeclock_3[20] 					= {941,942,943,944,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960}
	constant integer i_ch_timeclock_4[20] 					= {961,962,963,964,965,966,967,968,969,970,971,972,973,974,975,976,977,978,979,980}
	constant integer i_ch_timeclock_5[20] 					= {981,982,983,984,985,986,987,988,989,990,991,992,993,994,995,996,997,998,999,1000}
	
	//-----------------------------------------------------------------------------
	// Addresses ------------------------------------------------------------------
	//-----------------------------------------------------------------------------
	constant integer i_ad_timeclock_1[10] 					= {901,902,903,904,905,906,907,908,909,910}
	constant integer i_ad_timeclock_2[10] 					= {911,912,913,914,915,916,917,918,919,920}
	constant integer i_ad_timeclock_3[10] 					= {921,922,923,924,925,926,927,928,929,930}
	constant integer i_ad_timeclock_4[10] 					= {931,932,933,934,935,936,937,938,939,940}
	constant integer i_ad_timeclock_5[10] 					= {941,942,943,944,945,946,947,948,949,950}

define_call 'TC_updateUI'(integer zone)
{
	local_var integer i
	local_var sinteger morning_duration
	local_var sinteger evening_duration
	
	i = 1
	morning_duration = 0
	evening_duration = 0
	
	switch (zone)
	{
		case 1:
		{
			// SX9 Sdb Dome
			// Compute morning duration
			morning_duration = computeDuration(time_to_hour(timeclocks_morning[1]), timeclocks_duration[1][1])
			
			// Compute evening duration
			evening_duration = computeDuration(time_to_hour(timeclocks_evening[1]), timeclocks_duration[1][2])
			
			// Morning timeclock
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[1]),',0,', left_string(timeclocks_morning[1], 2), ':', mid_string(timeclocks_morning[1], 4, 2), ' - ', itoa(morning_duration), ':', mid_string(timeclocks_morning[1], 4, 2)"
			
			// Evening timeclock
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[2]),',0,', left_string(timeclocks_evening[1], 2), ':', mid_string(timeclocks_evening[1], 4, 2), ' - ', itoa(evening_duration), ':', mid_string(timeclocks_evening[1], 4, 2)"
			
			// Duration
			if (timeclocks_type[1] == MORNING)
				send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[3]),',0,', itoa(timeclocks_duration[1][1]), 'H'"
			else
				send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[3]),',0,', itoa(timeclocks_duration[1][2]), 'H'"
			
			// morning start hours
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[4]),',0,', left_string(timeclocks_morning[1], 2)"
			
			// morning start minutes
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[5]),',0,', mid_string(timeclocks_morning[1], 4, 2)"
			
			// evening start hours
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[6]),',0,', left_string(timeclocks_evening[1], 2)"
			
			// evening start minutes
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_1[7]),',0,', mid_string(timeclocks_evening[1], 4, 2)"
			
			// working days
			for (i = 1; i <= 7; i++)
			{
				if (timeclocks_days[1][i])
					on[i_TPTab, i_ch_timeclock_1[i+10]]
				else
					off[i_TPTab, i_ch_timeclock_1[i+10]]
			}
			
			// is morning enabled
			off[i_TPTab, i_ch_timeclock_1[18]]
			if (timeclocks_enabled[1][1])
				on[i_TPTab, i_ch_timeclock_1[18]]
			
			// is evening enabled
			off[i_TPTab, i_ch_timeclock_1[19]]
			if (timeclocks_enabled[1][2])
				on[i_TPTab, i_ch_timeclock_1[19]]
				
			// Force start SX
			off[i_TPTab, i_ch_timeclock_1[20]]
			if (force_start_btns[1] && HVACPower[ZONE_9_SX_SDBDOME] == 1)
			{
				on[i_TPTab, i_ch_timeclock_1[20]]
			} else if (force_start_btns[1] && HVACPower[ZONE_9_SX_SDBDOME] != 1) {
				on[i_TPTab, i_ch_timeclock_1[20]]
				send_command vdvHVAC, 'AW:1:953:1'
				wait 20 send_command vdvHVAC, 'AW:1:953:1'
			} else if (!force_start_btns[1] && HVACPower[ZONE_9_SX_SDBDOME] == 1) {
				off[i_TPTab, i_ch_timeclock_1[20]]
				send_command vdvHVAC, 'AW:1:953:2'
				wait 20 send_command vdvHVAC, 'AW:1:953:2'
			} else if (!force_start_btns[1] && HVACPower[ZONE_9_SX_SDBDOME] != 1) {
				off[i_TPTab, i_ch_timeclock_1[20]]
			}
		}
		
		case 2:
		{
			// SX12 Salle de douche
			// Compute morning duration
			morning_duration = computeDuration(time_to_hour(timeclocks_morning[2]), timeclocks_duration[2][1])
			
			// Compute evening duration
			evening_duration = computeDuration(time_to_hour(timeclocks_evening[2]), timeclocks_duration[2][2])
			
			// Morning timeclock
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[1]),',0,', left_string(timeclocks_morning[2], 2), ':', mid_string(timeclocks_morning[2], 4, 2), ' - ', itoa(morning_duration), ':', mid_string(timeclocks_morning[2], 4, 2)"
			
			// Evening timeclock
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[2]),',0,', left_string(timeclocks_evening[2], 2), ':', mid_string(timeclocks_evening[2], 4, 2), ' - ', itoa(evening_duration), ':', mid_string(timeclocks_evening[2], 4, 2)"
			
			// Duration
			if (timeclocks_type[2] == MORNING)
				send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[3]),',0,', itoa(timeclocks_duration[2][1]), 'H'"
			else
				send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[3]),',0,', itoa(timeclocks_duration[2][2]), 'H'"
			
			// morning start hours
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[4]),',0,', left_string(timeclocks_morning[2], 2)"
			
			// morning start minutes
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[5]),',0,', mid_string(timeclocks_morning[2], 4, 2)"
			
			// evening start hours
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[6]),',0,', left_string(timeclocks_evening[2], 2)"
			
			// evening start minutes
			send_command i_TPTab, "'^TXT-', itoa(i_ad_timeclock_2[7]),',0,', mid_string(timeclocks_evening[2], 4, 2)"
			
			// working days
			for (i = 1; i <= 7; i++)
			{
				if (timeclocks_days[2][i])
					on[i_TPTab, i_ch_timeclock_2[i+10]]
				else
					off[i_TPTab, i_ch_timeclock_2[i+10]]
			}
			
			// is morning enabled
			off[i_TPTab, i_ch_timeclock_2[18]]
			if (timeclocks_enabled[2][1])
				on[i_TPTab, i_ch_timeclock_2[18]]
			
			// is evening enabled
			off[i_TPTab, i_ch_timeclock_2[19]]
			if (timeclocks_enabled[2][2])
				on[i_TPTab, i_ch_timeclock_2[19]]
				
			// Force start SX
			off[i_TPTab, i_ch_timeclock_2[20]]
			if (force_start_btns[2] && HVACPower[ZONE_12_SX_SALLEDOUCHE] == 1)
			{
				on[i_TPTab, i_ch_timeclock_2[20]]
			} else if (force_start_btns[2] && HVACPower[ZONE_12_SX_SALLEDOUCHE] != 1) {
				on[i_TPTab, i_ch_timeclock_2[20]]
				send_command vdvHVAC, 'AW:1:1253:1'
				wait 20 send_command vdvHVAC, 'AW:1:1253:1'
			} else if (!force_start_btns[2] && HVACPower[ZONE_12_SX_SALLEDOUCHE] == 1) {
				off[i_TPTab, i_ch_timeclock_2[20]]
				send_command vdvHVAC, 'AW:1:1253:2'
				wait 20 send_command vdvHVAC, 'AW:1:1253:2'
			} else if (!force_start_btns[2] && HVACPower[ZONE_12_SX_SALLEDOUCHE] != 1) {
				off[i_TPTab, i_ch_timeclock_2[20]]
			}
		}
		
		default:
		{
			call 'TC_updateUI'(1)
			call 'TC_updateUI'(2)
		}
	}
}

define_function integer isCurrentDay(char today[3])
{
	local_var integer currentDay
	
	switch (today)
	{
		case 'MON': 	currentDay = DAY_MONDAY
		case 'TUE': 	currentDay = DAY_TUESDAY
		case 'WED': 	currentDay = DAY_WEDNESDAY
		case 'THU': 	currentDay = DAY_THURSDAY
		case 'FRI': 	currentDay = DAY_FRIDAY
		case 'SAT': 	currentDay = DAY_SATURDAY
		case 'SUN': 	currentDay = DAY_SUNDAY
	}
	
	return currentDay
}

define_function sinteger computeDuration(sinteger hour, sinteger duration)
{
	local_var sinteger finalDuration
	
	finalDuration = 0
	
	finalDuration = hour + duration
	if (finalDuration > 23)
	{
		if ((finalDuration - 24) >= 1)
			finalDuration = finalDuration - 24
		else
			finalDuration = 0
	}
	
	return finalDuration
}

define_event

	data_event[dvAMX]
	{
		online:
		{
			if (timeclocks_enabled[1][1] || timeclocks_enabled[1][2])	{ if (!timeline_active(ID_TIMECLOCK_1)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			if (timeclocks_enabled[2][1] || timeclocks_enabled[2][2])	{ if (!timeline_active(ID_TIMECLOCK_2)) timeline_create(ID_TIMECLOCK_2, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			//if (timeclocks_enabled[3])	{ if (!timeline_active(ID_TIMECLOCK_3)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			//if (timeclocks_enabled[4])	{ if (!timeline_active(ID_TIMECLOCK_4)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			//if (timeclocks_enabled[5])	{ if (!timeline_active(ID_TIMECLOCK_5)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
		}
	}
	
	data_event[i_TPTab]
	{
		online:
		{
			call 'TC_updateUI'($FF) // all zones
		}
		
		string:
		{
			local_var char str[200]
			local_var char tab[4][45]
			
			tab[1] = ''
			tab[2] = ''
			tab[3] = ''
			tab[4] = ''
			
			StringSplit(str, '@', tab)
				
			switch (tab[1])
			{
				case 'HVA':
				{
					switch (tab[2])
					{
						case 'Salle de bain Dome':
						{
							switch (tab[3])
							{
								case 'Update':
								case 'Save': 
									call 'TC_updateUI'(1)
							}
						}
						
						case 'Salle de douche':
						{
							switch (tab[3])
							{
								case 'Update':
								case 'Save':
									call 'TC_updateUI'(2)
							}
						}
						
						case 'Update':
						{
							call 'TC_updateUI'($FF)
						}
					}
				}
			}
		}
	}
	
	button_event[i_TPTab, i_ch_timeclock_1]
	{
		push:
		{
			local_var integer btn
			local_var sinteger tmpInt
			local_var char tmp[8]
			
			btn = get_last(i_ch_timeclock_1)
			
			switch (btn)
			{
				case 1: // + hours morning
				{
					tmpInt = time_to_hour(timeclocks_morning[1])
					
					if (tmpInt == 23)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[1] = "tmp, ':', mid_string(timeclocks_morning[1], 4, 2), ':00'"
				}
				
				case 2: // - hours morning
				{
					tmpInt = time_to_hour(timeclocks_morning[1])
					
					if (tmpInt == 0)
						tmp = '23'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[1] = "tmp, ':', mid_string(timeclocks_morning[1], 4, 2), ':00'"
				}
				
				case 3: // + minutes morning
				{
					tmpInt = time_to_minute(timeclocks_morning[1])
					
					if (tmpInt == 59)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[1] = "left_string(timeclocks_morning[1], 2), ':', tmp, ':00'"
				}
				
				case 4: // - minutes morning
				{
					tmpInt = time_to_minute(timeclocks_morning[1])
					
					if (tmpInt == 0)
						tmp = '59'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[1] = "left_string(timeclocks_morning[1], 2), ':', tmp, ':00'"
				}
				
				case 5: // + hours evening
				{
					tmpInt = time_to_hour(timeclocks_evening[1])
					
					if (tmpInt == 23)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[1] = "tmp, ':', mid_string(timeclocks_evening[1], 4, 2), ':00'"
				}
				
				case 6: // - hours evening
				{
					tmpInt = time_to_hour(timeclocks_evening[1])
					
					if (tmpInt == 0)
						tmp = '23'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[1] = "tmp, ':', mid_string(timeclocks_evening[1], 4, 2), ':00'"
				}
				
				case 7: // + minutes evening
				{
					tmpInt = time_to_minute(timeclocks_evening[1])
					
					if (tmpInt == 59)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[1] = "left_string(timeclocks_evening[1], 2), ':', tmp, ':00'"
				}
				
				case 8: // - minutes evening
				{
					tmpInt = time_to_minute(timeclocks_evening[1])
					
					if (tmpInt == 0)
						tmp = '59'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[1] = "left_string(timeclocks_evening[1], 2), ':', tmp, ':00'"
				}
				
				case 9: // + duration
				{
					if (timeclocks_type[1] == MORNING)
						tmpInt = timeclocks_duration[1][1]
					else
						tmpInt = timeclocks_duration[1][2]
					
					if (tmpInt + 1 > MAX_DURATION)
						tmpInt = 1
					else
						tmpInt = tmpInt + 1
					
					if (timeclocks_type[1] == MORNING)
						timeclocks_duration[1][1] = tmpInt
					else
						timeclocks_duration[1][2] = tmpInt
				}
				
				case 10: // - duration
				{
					if (timeclocks_type[1] == MORNING)
						tmpInt = timeclocks_duration[1][1]
					else
						tmpInt = timeclocks_duration[1][2]
					
					if (tmpInt - 1 <= 0)
						tmpInt = MAX_DURATION
					else
						tmpInt = tmpInt - 1
					
					if (timeclocks_type[1] == MORNING)
						timeclocks_duration[1][1] = tmpInt
					else
						timeclocks_duration[1][2] = tmpInt
				}
				
				case 11:
				case 12:
				case 13:
				case 14:
				case 15:
				case 16:
				case 17:
				{
					timeclocks_days[1][btn - 10] = !timeclocks_days[1][btn - 10]
				}
				
				case 18:
				{
					timeclocks_enabled[1][1] = !timeclocks_enabled[1][1]
				}
				
				case 19:
				{
					timeclocks_enabled[1][2] = !timeclocks_enabled[1][2]
				}
				
				case 20:
				{
					force_start_btns[1] = !force_start_btns[1]
				}
			}
			
			// check if timelines needs to be enabled
			if (timeclocks_enabled[1][1] || timeclocks_enabled[1][2])	{ if (!timeline_active(ID_TIMECLOCK_1)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			
			// update UI
			call 'TC_updateUI'(1)
		}
	}
	
	button_event[i_TPTab, i_ch_timeclock_2]
	{
		push:
		{
			local_var integer btn
			local_var sinteger tmpInt
			local_var char tmp[8]
			
			btn = get_last(i_ch_timeclock_2)
			
			switch (btn)
			{
				case 1: // + hours morning
				{
					tmpInt = time_to_hour(timeclocks_morning[2])
					
					if (tmpInt == 23)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[2] = "tmp, ':', mid_string(timeclocks_morning[2], 4, 2), ':00'"
				}
				
				case 2: // - hours morning
				{
					tmpInt = time_to_hour(timeclocks_morning[2])
					
					if (tmpInt == 0)
						tmp = '23'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[2] = "tmp, ':', mid_string(timeclocks_morning[2], 4, 2), ':00'"
				}
				
				case 3: // + minutes morning
				{
					tmpInt = time_to_minute(timeclocks_morning[2])
					
					if (tmpInt == 59)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[2] = "left_string(timeclocks_morning[2], 2), ':', tmp, ':00'"
				}
				
				case 4: // - minutes morning
				{
					tmpInt = time_to_minute(timeclocks_morning[2])
					
					if (tmpInt == 0)
						tmp = '59'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_morning[2] = "left_string(timeclocks_morning[2], 2), ':', tmp, ':00'"
				}
				
				case 5: // + hours evening
				{
					tmpInt = time_to_hour(timeclocks_evening[2])
					
					if (tmpInt == 23)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[2] = "tmp, ':', mid_string(timeclocks_evening[2], 4, 2), ':00'"
				}
				
				case 6: // - hours evening
				{
					tmpInt = time_to_hour(timeclocks_evening[2])
					
					if (tmpInt == 0)
						tmp = '23'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[2] = "tmp, ':', mid_string(timeclocks_evening[2], 4, 2), ':00'"
				}
				
				case 7: // + minutes evening
				{
					tmpInt = time_to_minute(timeclocks_evening[2])
					
					if (tmpInt == 59)
						tmp = '00'
					else
						tmp = itoa(tmpInt + 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[2] = "left_string(timeclocks_evening[2], 2), ':', tmp, ':00'"
				}
				
				case 8: // - minutes evening
				{
					tmpInt = time_to_minute(timeclocks_evening[2])
					
					if (tmpInt == 0)
						tmp = '59'
					else
						tmp = itoa(tmpInt - 1)
						
					if (atoi(tmp) < 10)
						tmp = "'0', tmp"
					
					timeclocks_evening[2] = "left_string(timeclocks_evening[2], 2), ':', tmp, ':00'"
				}
				
				case 9: // + duration
				{
					if (timeclocks_type[2] == MORNING)
						tmpInt = timeclocks_duration[2][1]
					else
						tmpInt = timeclocks_duration[2][2]
					
					if (tmpInt + 1 > MAX_DURATION)
						tmpInt = 1
					else
						tmpInt = tmpInt + 1
					
					if (timeclocks_type[2] == MORNING)
						timeclocks_duration[2][1] = tmpInt
					else
						timeclocks_duration[2][2] = tmpInt
				}
				
				case 10: // - duration
				{
					if (timeclocks_type[2] == MORNING)
						tmpInt = timeclocks_duration[2][1]
					else
						tmpInt = timeclocks_duration[2][2]
					
					if (tmpInt - 1 <= 0)
						tmpInt = MAX_DURATION
					else
						tmpInt = tmpInt - 1
					
					if (timeclocks_type[2] == MORNING)
						timeclocks_duration[2][1] = tmpInt
					else
						timeclocks_duration[2][2] = tmpInt
				}
				
				case 11:
				case 12:
				case 13:
				case 14:
				case 15:
				case 16:
				case 17:
				{
					timeclocks_days[2][btn - 10] = !timeclocks_days[2][btn - 10]
				}
				
				case 18:
				{
					timeclocks_enabled[2][1] = !timeclocks_enabled[2][1]
				}
				
				case 19:
				{
					timeclocks_enabled[2][2] = !timeclocks_enabled[2][2]
				}
				
				case 20:
				{
					force_start_btns[2] = !force_start_btns[2]
				}
			}
			
			// check if timelines needs to be enabled
			if (timeclocks_enabled[2][1] || timeclocks_enabled[2][2])	{ if (!timeline_active(ID_TIMECLOCK_1)) timeline_create(ID_TIMECLOCK_1, TIMING_ONE_MINUTE, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT) }
			
			// update UI
			call 'TC_updateUI'(2)
		}
	}
	
	timeline_event[ID_TIMECLOCK_1]
	{
		local_var char checkCurrentDay
		local_var sinteger duration
		
		// check if current day should be active
		checkCurrentDay = (timeclocks_days[1][isCurrentDay(DAY)] == 1)
		
		// calculate total duration morning timeclock
		duration = computeDuration(time_to_hour(timeclocks_morning[1]), timeclocks_duration[1][1])
		
		if (timeclocks_enabled[1][1] && checkCurrentDay)
		{
			if (time_to_hour(time) == time_to_hour(timeclocks_morning[1]))
			{
				if (time_to_minute(time) == time_to_minute(timeclocks_morning[1]))
				{
					send_string 0, 'EVENT Timeclock: SS Salle de bain Dome (SX9) ENABLED !!'
					send_command vdvHVAC, 'AW:1:953:1'
					wait 20 send_command vdvHVAC, 'AW:1:953:1'
				}
			}
			else if ((time_to_hour(time) == duration) && (time_to_minute(time) == time_to_minute(timeclocks_morning[1])))
			{
				send_string 0, 'EVENT Timeclock: SS Salle de bain Dome (SX9) DISABLED !!'
				send_command vdvHVAC, 'AW:1:953:2'
				wait 20 send_command vdvHVAC, 'AW:1:953:2'
			}
		}
		
		// calculate total duration evening timeclock
		duration = computeDuration(time_to_hour(timeclocks_evening[1]), timeclocks_duration[1][2])
		
		if (timeclocks_enabled[1][2] && checkCurrentDay)
		{
			if (time_to_hour(time) == time_to_hour(timeclocks_evening[1]))
			{
				if (time_to_minute(time) == time_to_minute(timeclocks_evening[1]))
				{
					send_string 0, 'EVENT Timeclock: SS Salle de bain Dome (SX9) ENABLED !!'
					send_command vdvHVAC, 'AW:1:953:1'
					wait 20 send_command vdvHVAC, 'AW:1:953:1'
				}
			}
			else if ((time_to_hour(time) == duration) && (time_to_minute(time) == time_to_minute(timeclocks_evening[1])))
			{
				send_string 0, 'EVENT Timeclock: SS Salle de bain Dome (SX9) DISABLED !!'
				send_command vdvHVAC, 'AW:1:953:2'
				wait 20 send_command vdvHVAC, 'AW:1:953:2'
			}
		}
	}
	
	timeline_event[ID_TIMECLOCK_2]
	{
		local_var char checkCurrentDay
		local_var sinteger duration
		
		// check if current day should be active
		checkCurrentDay = (timeclocks_days[2][isCurrentDay(DAY)] == 1)
		
		// calculate total duration morning timeclock
		duration = computeDuration(time_to_hour(timeclocks_morning[2]), timeclocks_duration[2][1])
		
		if (timeclocks_enabled[2][1] && checkCurrentDay)
		{
			if (time_to_hour(time) == time_to_hour(timeclocks_morning[2]))
			{
				if (time_to_minute(time) == time_to_minute(timeclocks_morning[2]))
				{
					send_string 0, 'EVENT Timeclock: SS Salle de douche (SX12) ENABLED !!'
					send_command vdvHVAC, 'AW:1:1253:1'
					wait 20 send_command vdvHVAC, 'AW:1:1253:1'
				}
			}
			else if ((time_to_hour(time) == duration) && (time_to_minute(time) == time_to_minute(timeclocks_morning[2])))
			{
				send_string 0, 'EVENT Timeclock: SS Salle de douche (SX12) DISABLED !!'
				send_command vdvHVAC, 'AW:1:1253:2'
				wait 20 send_command vdvHVAC, 'AW:1:1253:2'
			}
		}
		
		// calculate total duration evening timeclock
		duration = computeDuration(time_to_hour(timeclocks_evening[2]), timeclocks_duration[2][2])
		
		if (timeclocks_enabled[2][2] && checkCurrentDay)
		{
			if (time_to_hour(time) == time_to_hour(timeclocks_evening[2]))
			{
				if (time_to_minute(time) == time_to_minute(timeclocks_evening[2]))
				{
					send_string 0, 'EVENT Timeclock: SS Salle de douche (SX12) ENABLED !!'
					send_command vdvHVAC, 'AW:1:1253:1'
					wait 20 send_command vdvHVAC, 'AW:1:1253:1'
				}
			}
			else if ((time_to_hour(time) == duration) && (time_to_minute(time) == time_to_minute(timeclocks_evening[2])))
			{
				send_string 0, 'EVENT Timeclock: SS Salle de douche (SX12) DISABLED !!'
				send_command vdvHVAC, 'AW:1:1253:2'
				wait 20 send_command vdvHVAC, 'AW:1:1253:2'
			}
		}
	}
