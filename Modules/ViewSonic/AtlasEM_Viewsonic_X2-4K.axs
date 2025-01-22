module_name='AtlasEM_Viewsonic_X2-4K'(dev dvProj, dev vdvProj, integer projPower, char projInput[])
(***********************************************************)
(*  FILE CREATED ON: 11/08/2024  AT: 12:51:50              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 12/11/2024  AT: 14:30:35        *)
(***********************************************************)

(*
	Viewsonic projectors control module
	---------------------------------
	Tested on X2-4K
	
	Release notes:
		*v1.0 : Module creation.
	
	---------------------------------
	Author : 	AEM <alex@atlas-em.dev>
	Version : 	1.0
	Date : 		08-11-2024
*)

#include '_utils'

(*
Source: https://www.viewsonicglobal.com/public/products_download/user_guide/projector/X1-4K/RS-232%20LAN%20Control%20Protocol%20Specification%20V1.5.pdf?pass

Notes: Cooldown is 5 minutes long before powering off completely !

// write packet
0x06 0x14 0x00 LSB MSB 0x34 cmd2 cmd3 data checksum

// -- writing --

// Power On
0x06 0x14 0x00 0x04 0x00 0x34 0x11 0x00 0x00 0x5D

// Power Off
0x06 0x14 0x00 0x04 0x00 0x34 0x11 0x01 0x00 0x5E

// Quick Power On
0x06 0x14 0x00 0x04 0x00 0x34 0x11 0x0B 0x01 0x69

// Quick Power Off
0x06 0x14 0x00 0x04 0x00 0x34 0x11 0x0B 0x00 0x68

// Set input to HDMI 1
0x06 0x14 0x00 0x04 0x00 0x34 0x13 0x01 0x03 0x63

// Set input to HDMI 2
0x06 0x14 0x00 0x04 0x00 0x34 0x13 0x01 0x07 0x67

// Set input to HDMI 3
0x06 0x14 0x00 0x04 0x00 0x34 0x13 0x01 0x09 0x69

// Set input to HDMI 4 / MHL
0x06 0x14 0x00 0x04 0x00 0x34 0x13 0x01 0x0e 0x6e

// -- reading --

// Get power status
0x07 0x14 0x00 0x05 0x00 0x34 0x00 0x00 0x11 0x00 0x5E

// Get input status
0x07 0x14 0x00 0x05 0x00 0x34 0x00 0x00 0x13 0x01 0x61

// Get error status
0x07 0x14 0x00 0x05 0x00 0x34 0x00 0x00 0x0C 0x0D 0x66
*)

define_constant
	
	ID_TIMELINE_PROJ 			= 55001
	
	// SET requests
	set_power_on[10] 			= {$06, $14, $00, $04, $00, $34, $11, $00, $00, $5D}
	set_power_off[10] 			= {$06, $14, $00, $04, $00, $34, $11, $01, $00, $5E}
	set_quick_power_on[10] 		= {$06, $14, $00, $04, $00, $34, $11, $0B, $01, $69}
	set_quick_power_off[10] 	= {$06, $14, $00, $04, $00, $34, $11, $0B, $00, $68}
	set_input_hdmi1[10]			= {$06, $14, $00, $04, $00, $34, $13, $01, $03, $63}
	set_input_hdmi2[10]			= {$06, $14, $00, $04, $00, $34, $13, $01, $07, $67}
	set_input_hdmi3[10]			= {$06, $14, $00, $04, $00, $34, $13, $01, $09, $69}
	set_input_hdmi4[10]			= {$06, $14, $00, $04, $00, $34, $13, $01, $0E, $6E}
	
	// Responses from SET
	res_success[6]				= {$03, $14, $00, $00, $00, $14}
	
	// GET requests
	get_power_status[11] 		= {$07, $14, $00, $05, $00, $34, $00, $00, $11, $00, $5E}
	get_input_status[11] 		= {$07, $14, $00, $05, $00, $34, $00, $00, $13, $01, $61}
	get_error_status[11] 		= {$07, $14, $00, $05, $00, $34, $00, $00, $0C, $0D, $66}
	
	// Response from GET
	res_power_on[9]				= {$05, $14, $00, $03, $00, $00, $00, $01, $18}
	res_power_off[9]			= {$05, $14, $00, $03, $00, $00, $00, $00, $17}
	res_power_warmup[9]			= {$05, $14, $00, $03, $00, $00, $00, $02, $19}
	res_power_cooldown[9]		= {$05, $14, $00, $03, $00, $00, $00, $03, $1A}
	res_input_hdmi1[9]			= {$05, $14, $00, $03, $00, $00, $00, $03, $1A}
	res_input_hdmi2[9]			= {$05, $14, $00, $03, $00, $00, $00, $07, $1E}
	res_input_hdmi3[9]			= {$05, $14, $00, $03, $00, $00, $00, $09, $20}
	res_input_hdmi4[9]			= {$05, $14, $00, $03, $00, $00, $00, $0E, $25}
	
define_variable

	char _debug = true
	
	constant long TIMING_TEN_SECONDS[1] = {10000}
	
	// request history
	// 0 = SET, 1 = GET
	volatile char last_request[11]
	char request_type 					= 0

define_call 'Debug' (char message[])
{
	if (_debug)
		send_string 0, "'AtlasEM_Viewsonic_X2-4K (', itoa(dvProj.port), ') - ', message"
}

define_function WritePacket(char cmd[])
{
	last_request = cmd
	send_string dvProj, "cmd"
}

define_function FeedbackAnalysis(char packet[])
{
	if (_debug)
		call 'Debug'(packet)
		
	switch (packet)
	{
		case res_power_on: 			projPower = 1
		case res_power_off: 		projPower = 0
		case res_power_warmup: 		projPower = 2
		case res_power_cooldown: 	
		case res_input_hdmi1: 		
		{
			if (last_request == get_power_status)
				projPower = 3
			else
				projInput = 'HDMI1'
		}
		case res_input_hdmi2: 		projInput = 'HDMI2'
		case res_input_hdmi3: 		projInput = 'HDMI3'
		case res_input_hdmi4: 		projInput = 'HDMI4'
	}
}

define_event

	data_event[dvProj]
	{
		online:
		{
			send_command dvProj, 'SET BAUD 115200,N,8,1'
			
			wait 50 if (!timeline_active(ID_TIMELINE_PROJ)) timeline_create(ID_TIMELINE_PROJ, TIMING_TEN_SECONDS, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
		}
		
		string:
		{
			FeedbackAnalysis(data.text)
		}
	}
	
	data_event[vdvProj]
	{
		command:
		{
			local_var char cmd[200]
			local_var char tab[4][25]
			
			tab[1] = ''
			tab[2] = ''
			tab[3] = ''
			tab[4] = ''
			
			cmd = upper_string(data.text)
			StringSplit(cmd, ':', tab)
			
			switch (tab[1])
			{
				case 'POWER':
				{
					request_type = 0
					
					switch (tab[2])
					{
						case 'ON':
						{
							WritePacket(set_power_on)
						}
						case 'OFF':
						{
							WritePacket(set_power_off)
						}
						case 'QUICK':
						{
							switch (tab[3])
							{
								case 'ON':
								{
									WritePacket(set_quick_power_on)
								}
								
								case 'OFF':
								{
									WritePacket(set_quick_power_off)
								}
							}
						}
					}
				}
				
				case 'INPUT':
				{
					request_type = 0
					
					switch (tab[2])
					{
						case 'HDMI1':
						{
							WritePacket(set_input_hdmi1)
						}
						
						case 'HDMI2':
						{
							WritePacket(set_input_hdmi2)
						}
						
						case 'HDMI3':
						{
							WritePacket(set_input_hdmi3)
						}
						
						case 'HDMI4':
						{
							WritePacket(set_input_hdmi4)
						}
					}
				}
				
				case 'GET':
				{
					request_type = 1
					
					switch (tab[2])
					{
						case 'POWER':
						{
							WritePacket(get_power_status)
						}
						
						case 'INPUT':
						{
							WritePacket(get_input_status)
						}
						
						case 'ERROR':
						{
							WritePacket(get_error_status)
						}
					}
				}
			}
		}
	}
	
	timeline_event[ID_TIMELINE_PROJ]
	{
		WritePacket(get_power_status)
		
		wait 50
		{
			if (projPower == true)
			{
				WritePacket(get_input_status)
			}
		}
	}