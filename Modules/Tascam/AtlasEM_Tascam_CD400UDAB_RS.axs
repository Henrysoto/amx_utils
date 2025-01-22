module_name='AtlasEM_Tascam_CD400UDAB_RS'(dev dvTascam, dev vdvTascam, dev TPs[], integer machineId, integer currentPreset, char currentFreq[6], char power, char input[3], char state[], integer chCodes[], char presetList[][6])
(***********************************************************)
(*  FILE CREATED ON: 01/20/2025  AT: 14:34:04              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 01/22/2025  AT: 19:57:01        *)
(***********************************************************)

(*
	Tascam RS-232C/TELNET Protocol Spec v1.21
	---------------------------------
	Tested on CD-400U/CD-400UDAB
	
	Release notes:
		*v1.0 : Module creation.
	
	---------------------------------
	Author : 	AEM <alex@atlas-em.dev>
	Version : 	1.0
	Date : 		21/01/2025
*)

#include '_utils'


(* 
	Source: https://www.tascam.eu/en/docs/CD-400U_RS-232C-spec_v121.pdf
	
	Basic Packet format:
	
	Byte_1	Byte_2	Byte_3+Byte_4	Byte_5	...		Byte_N	
	LF		ID		Command			Data			CR
	
	ID = Machine ID (usually 0 if only one device)
	
	- ASCII (PLAY packet example):
		"$0A,'012',$0D"
	- ASCII (Direct Track Search Preset packet example for track 12):
		"$0A,'0231200',$0D"
		
	Vendor Packet format:
	
	Byte_1	Byte_2	Byte_3+Byte_4 	Byte_5+Byte_6	Byte_7+Byte_8	Byte_9	...		Byte_N
	LF		ID		Command			Category Code	Sub Command		Param			CR
	
	NOTES:
		- This device is meant to stay powered on, there are no power on/off command but
		  it will return a power status on initial startup.
		- The stop command doesn't stop the device from playing if it's set to FM/DAB input mode.
		  It will switch between frequency and preset station if you send a stop command.
*)

define_constant
	
	ID_TIMELINE_TASCAM = 55002
	
	// SET requests
	set_ready_on 			= '1401'
	set_play				= '12'
	set_stop				= '10'	// will switch between fm/preset if input is fm
	set_search_forward		= '1600'
	set_search_reverse		= '1601'
	set_search_f_forward	= '1610'
	set_search_f_reverse	= '1611'
	set_track_next			= '1A00'
	set_track_prev			= '1A01'
	set_dtsp				= '23'
	set_input_sd			= '7F0100'
	set_input_usb			= '7F0110'
	set_input_cd			= '7F0111'
	set_input_bt			= '7F0120'
	set_input_dab			= '7F0130'
	set_input_fm			= '7F0131'
	set_input_aux			= '7F0140'
	
	// GET requests
	get_information 		= '0F'
	get_current_input		= '7F01FF'
	get_track_number		= '55'
	get_current_freq		= '57' 	// freq,track,preset
	get_mecha_sense			= '50'
	
	// RETURN responses
	ret_power_status		= 'F4'
	ret_status				= 'F6' 	// status change
	ret_status_mecha		= '00'	// play,stop,ready change notification
	ret_status_tuner		= '03' 	// track,tuner,preset,freq change notification
	ret_information			= '8F'
	ret_track_number		= 'D5'
	ret_current_freq 		= 'D7'
	ret_vendor				= 'FF'
	ret_mecha_sense			= 'D0'
	ret_mecha_nomedia		= '00'
	ret_mecha_disceject		= '01'
	ret_mecha_stop			= '10'
	ret_mecha_play			= '11'
	ret_mecha_ready			= '12'
	ret_mecha_forward		= '28'
	ret_mecha_reverse		= '29'
	ret_mecha_writing		= '83'
	ret_mecha_unknown		= 'FF'
	ret_device_sd			= '00'
	ret_device_cd			= '11'
	ret_device_usb			= '10'
	ret_device_bt			= '20'
	ret_device_dab			= '30' 	// FM (CD-400U) / DAB (CD400-UDAB)
	ret_device_fm			= '31' 	// AM (CD-400U) / FM (CD400-UDAB)
	ret_device_aux			= '40'
	
	// VENDOR specifics
	cat_device_select		= '01'
	cat_playback			= '07'
	
	// ILLEGAL status (error)
	error_status 			= 'F2'
	
define_variable

	// Enable debug messages
	char _debug 							= true
	
	// timeline timings
	constant long TIMING_FIVE_SECONDS[1] 	= {5000}
	constant long TIMING_TEN_SECONDS[1] 	= {10000}
	constant long TIMING_THIRTY_SECONDS[1] 	= {30000}
	
	// commands history
	persistent char lastCommand[20]

define_call 'Debug'(char message[])
{
	if (_debug)
		send_string 0, "'AtlasEM_Tascam_CD400UDAB_RS (', itoa(dvTascam.port),') - ', message"
}

define_function char[6] ParseFrequency(char data[])
{
	local_var char tmp[15]
	local_var char out[6]
	
	tmp = "data[5],data[6],data[7],data[8],data[9]"
	
	if (tmp[1] == '0')
	{
		out = "tmp[2],tmp[3],'.',tmp[4],tmp[5]"
	}
	else
	{
		out = "tmp[1],tmp[2],tmp[3],'.',tmp[4],tmp[5]"
	}
	
	//call 'Debug'("'Current frequency is: ', out, 'Mhz'")
	
	return out
}

define_function integer FindCurrentPreset(char freq[])
{
	// This function allows you to match the current playing frequency 
	// with the Preset_Radio list to find out which btn channel index should be set active
	
	local_var integer i
	local_var integer idx
	
	for (i = 1; i <= length_array(presetList); i++)
	{
		if (freq == presetList[i])
			idx = i
	}
	
	call 'Debug'("'Current preset and frequency are: ', itoa(idx), ' - ', presetList[idx], 'Mhz'")
	
	return idx
}

define_function char[4] FormatPresetStr(integer preset)
{
	local_var char tmp[4]
	
	if (preset > 99)
	{
		tmp = "itoa(preset), '0'"
	}
	else if (preset > 9)
	{
		tmp = "itoa(preset), '00'"
	}
	else
	{
		tmp = "itoa(preset), '000'"
	}
	
	return tmp
}

define_function WritePacket(char cmd[])
{
	lastCommand = "'LF,', itoa(machineId), ',', cmd, ',CR'"
	send_string dvTascam, "$0A, itoa(machineId), cmd, $0D"
	
	call 'Debug'("'Sent command: ', lastCommand")
}

define_function FeedbackAnalysis(char packet[])
{
	stack_var char tmp[50]
	stack_var char cmd[2]
	stack_var char data[20]
	stack_var integer i
	stack_var char mId[1]
	
	call 'Debug'("'Received packet from device: ', packet")
	
	// Convert packet to a full string and removes line feed & carriage return symbols
	for (i = 1; i <= length_string(packet); i++)
	{
		if (packet[i] == $0A || packet[i] == $0D)
			continue
		tmp = "tmp, packet[i]"
	}
	
	// Extract matching machine id
	mId = remove_string(tmp, itoa(machineId), 1)
	
	// Stop if machine id doesn't match module's parameter
	if (mId <> '')
	{
		// Extract command
		cmd = remove_string(tmp, "tmp[1], tmp[2]", 1)
		
		// Data
		data = tmp
		
		switch (cmd)
		{
			case ret_power_status:
			{
				power = true
			}
			
			case ret_status:
			{
				switch (data)
				{
					case ret_status_mecha: WritePacket(get_mecha_sense)
					case ret_status_tuner: WritePacket(get_current_freq)
				}
			}
			
			case ret_mecha_sense:
			{
				switch (data)
				{
					case ret_mecha_nomedia:		state = 'noMedia'
					case ret_mecha_disceject:	state = 'discEject'
					case ret_mecha_stop:		state = 'stop'
					case ret_mecha_play:		state = 'play'
					case ret_mecha_ready:		state = 'ready'
					case ret_mecha_forward:		state = 'forward'
					case ret_mecha_reverse:		state = 'reverse'
					case ret_mecha_writing:		state = 'writing'
					case ret_mecha_unknown:		state = 'unknown'
				}
				
				call 'Debug'("'State set to: ', state")
			}
			
			case ret_current_freq:
			{	
				if (input == 'FM')
				{
					currentFreq = ParseFrequency(data)
					currentPreset = FindCurrentPreset(currentFreq)
				}
				else
				{
					call 'Debug'('Error input must be FM to retrieve a frequency')
				}
			}
			
			case ret_vendor:
			{
				switch ("data[1], data[2]")
				{
					case cat_device_select:
					{
						switch ("data[3], data[4]")
						{
							case ret_device_sd:		input = 'SD'
							case ret_device_usb:	input = 'USB'
							case ret_device_cd:		input = 'CD'
							case ret_device_bt:		input = 'BT'
							case ret_device_dab:	input = 'DAB'
							case ret_device_fm:		input = 'FM'
							case ret_device_aux:	input = 'AUX'
						}
					}
					
					case cat_playback:
					{
						call 'Debug'('<Play Area Select Return> responses not implemented yet')
					}
				}
			}
			
			case error_status:
			{
				call 'Debug'("'Command error: ', lastCommand")
			}
			
			case ret_information:
			{
				call 'Debug'(data)
				power = true
			}
		}
	}
	else
	{
		call 'Debug'("'Module machine ID is set to ', itoa(machineId), ' but id parsed from device is different!'")
	}
}

define_event

	data_event[dvTascam]
	{
		online:
		{
			send_command dvTascam, 'SET BAUD 9600,N,8,1'
			if (!timeline_active(ID_TIMELINE_TASCAM)) timeline_create(ID_TIMELINE_TASCAM, TIMING_THIRTY_SECONDS, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
		}
		
		string:
		{
			FeedbackAnalysis(data.text)
		}
	}
	
	data_event[vdvTascam]
	{
		command:
		{
			local_var char cmd[50]
			local_var char tab[4][25]
			
			cmd = upper_string(data.text)
			StringSplit(cmd, ':', tab)
			
			switch (tab[1])
			{
				case 'READY':
				{
					switch (tab[2])
					{
						case 'ON': WritePacket(set_ready_on)
						case 'OFF':{}
					}
				}
				
				case 'INPUT':
				{
					switch (tab[2])
					{
						case 'TUNER': 	WritePacket(set_input_fm)
						case 'CD':		WritePacket(set_input_cd)
						case 'USB':		WritePacket(set_input_usb)
						case 'DAB':		WritePacket(set_input_dab)
						case 'BT':		WritePacket(set_input_bt)
						case 'SD':		WritePacket(set_input_sd)
						case 'AUX':		WritePacket(set_input_aux)
					}
				}
				
				case 'REMOTE':
				{
					switch (tab[2])
					{
						case 'PLAY':	WritePacket(set_play)
						case 'STOP':	WritePacket(set_stop)
						case 'SEARCH':
						{
							switch (tab[3])
							{
								case 'FORWARD':	WritePacket(set_search_forward)
								case 'REVERSE':	WritePacket(set_search_reverse)
							}
						}
						
						case 'FASTSEARCH':
						{
							switch (tab[3])
							{
								case 'FORWARD':	WritePacket(set_search_f_forward)
								case 'REVERSE':	WritePacket(set_search_f_reverse)
							}
						}
						
						case 'PRESET':
						{
							WritePacket("set_dtsp, FormatPresetStr(atoi(tab[3]))")
						}
					}
				}
				
				// Send direct command
				case 'DIRECT':
				{
					if (_debug)
						WritePacket(tab[2])
				}
			}
		}
	}
	
	button_event[TPs, chCodes]
	{
		push:
		{
			stack_var integer _btn
			
			_btn = get_last(chCodes)
			
			call 'Debug'("'Button ', itoa(button.input.channel), ' pushed on TP ', itoa(button.sourcedev.number), ':', itoa(button.sourcedev.port), ':', itoa(button.sourcedev.system)")
			
			select
			{
				active (_btn <= 45): WritePacket("set_dtsp, FormatPresetStr(_btn)")
			}
		}
	}
	
	timeline_event[ID_TIMELINE_TASCAM]
	{
		WritePacket(get_current_input)
		
		wait 20 {
			if (input <> 'FM')
			{
				WritePacket(set_input_fm)
				call 'Debug'('Setting input to FM')
			}
		}
		
		wait 40 WritePacket(get_current_freq)
	}