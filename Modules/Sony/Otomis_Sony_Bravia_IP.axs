module_name='Otomis_Sony_Bravia_IP' (dev dvTV, dev vdvTV, dev TPs[], char ipAddr[15], char isProxyEnabled, char _power, char _mute, integer chCodes[])
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/31/2022  AT: 14:38:45        *)
(***********************************************************)

#include '_utils'

/*
	Sony Bravia IP Control Protocol
	---------------------------------
	
	References:
		- https://pro-bravia.sony.net/develop/integrate/ssip/data-format/
		- https://shop.kindermann.de/erp/KCO/avs/3/3005/3005000168/01_Anleitungen+Doku/Steuerungsprotokoll_1.pdf
	
	---------------------------------
	Tested on model KD-43X85J
	
	TV options (must be enabled):
		- Enable SIMPLE IP CONTROL
		- Enable RENDERER
	
	Release notes:
		*v1.0 : Module creation. 
	
	---------------------------------
	Author : 	AEM
	Version : 	1.0
	Date : 		2021-11-24
*/


define_constant
	
	// TCP IP Port
	TCP_PORT 	= 20060
	
	// Message max length
	MSG_MAX_LEN	= 24
	
	// Message header (byte [1])
	H_HEADER 	= '*S'
	H_FOOTER 	= $0A
	
	// Message type (byte[2])
	MT_CONTROL 	= 'C'
	MT_REQUEST 	= 'E'
	MT_RESPONSE = 'A'
	MT_NOTIFY 	= 'N'
	
	// Command head (FourCC) (byte [3-6])
	CMD_POWER 		= 'POWR'
	CMD_VOLUME		= 'VOLU'
	CMD_MUTE		= 'AMUT'
	CMD_INPUT		= 'INPT'
	CMD_IR			= 'IRCC'
	
	// Command parameters (byte [7-22])
	POWER_OFF		= '0000000000000000'
	POWER_ON		= '0000000000000001'
	
	SET_VOLUME 		= '0000000000000000'
	MUTE_AUDIO		= '0000000000000001'
	UNMUTE_AUDIO	= '0000000000000000'
	
	INPUT_TNT		= '0000000100000000' // Might not be working
	INPUT_HDMI1		= '0000000100000001'
	INPUT_HDMI2		= '0000000100000002'
	INPUT_HDMI3		= '0000000100000003'
	INPUT_HDMI4		= '0000000100000004'
	INPUT_MIRROR	= '0000000500000001'
	
	// IR Commands (byte [7-22])
	REMOTE_DISPLAY 	= '0000000000000005'
	REMOTE_HOME 	= '0000000000000006'
	REMOTE_OPTIONS 	= '0000000000000007'
	REMOTE_RETURN 	= '0000000000000008'
	REMOTE_UP 		= '0000000000000009'
	REMOTE_DOWN 	= '0000000000000010'
	REMOTE_RIGHT 	= '0000000000000011'
	REMOTE_LEFT 	= '0000000000000012'
	REMOTE_OK 		= '0000000000000013'
	REMOTE_RED 		= '0000000000000014'
	REMOTE_GREEN 	= '0000000000000015'
	REMOTE_YELLOW 	= '0000000000000016'
	REMOTE_BLUE 	= '0000000000000017'
	REMOTE_NUM_1 	= '0000000000000018'
	REMOTE_NUM_2 	= '0000000000000019'
	REMOTE_NUM_3 	= '0000000000000020'
	REMOTE_NUM_4 	= '0000000000000021'
	REMOTE_NUM_5 	= '0000000000000022'
	REMOTE_NUM_6 	= '0000000000000023'
	REMOTE_NUM_7 	= '0000000000000024'
	REMOTE_NUM_8 	= '0000000000000025'
	REMOTE_NUM_9 	= '0000000000000026'
	REMOTE_NUM_0 	= '0000000000000027'
	REMOTE_VOLUP	= '0000000000000030'
	REMOTE_VOLDOWN	= '0000000000000031'
	REMOTE_VOLMUTE	= '0000000000000032'
	REMOTE_CHUP		= '0000000000000033'
	REMOTE_CHDOWN	= '0000000000000034'
	REMOTE_SUBTITLE = '0000000000000035'
	REMOTE_FORWARD 	= '0000000000000077'
	REMOTE_PLAY 	= '0000000000000078'
	REMOTE_REWIND 	= '0000000000000079'
	REMOTE_PREV 	= '0000000000000080'
	REMOTE_STOP 	= '0000000000000081'
	REMOTE_NEXT 	= '0000000000000082'
	REMOTE_PAUSE 	= '0000000000000084'
	REMOTE_POWER	= '0000000000000098'
	REMOTE_HDMI1	= '0000000000000124'
	REMOTE_HDMI2	= '0000000000000125'
	REMOTE_HDMI3	= '0000000000000126'
	REMOTE_HDMI4	= '0000000000000127'
	REMOTE_ACTION	= '0000000000000129'
	
	// Answers
	RES_SUCCESS		= '0000000000000000'
	RES_ERROR		= 'FFFFFFFFFFFFFFFF'
	
	// Request
	REQ_FILL		= '################'
	
	// Timeline
	TIMELINE_TV_ID 	= 55001
	
	
define_variable

	constant long EVERY_30S_TIMES[1]	= {15000}
	volatile char _input[10] 			= ''
	volatile integer _volume			= 0
	volatile char _online				= false
	volatile char _sendingData			= false
	volatile char lastSentCmdType[1]	= ''
	constant char _channels[10][16]		= {
		'0000000000000018', 	// 1
		'0000000000000019', 	// 2
		'0000000000000020', 	// 3
		'0000000000000021', 	// 4
		'0000000000000022', 	// 5
		'0000000000000023', 	// 6
		'0000000000000024', 	// 7
		'0000000000000025', 	// 8
		'0000000000000026', 	// 9
		'0000000000000027' 		// 0
	}

define_call 'Debug' (integer logLevel, char message[])
{
	amx_log(logLevel, "'Otomis_Sony_Bravia_IP (', ipAddr, ') - ', message")
}

define_function FeedbackAnalysis (char fdbk[])
{
	local_var char type
	local_var integer value
	local_var char error[50]
	
	call 'Debug'(amx_error, "'Feedback analysis: ', fdbk")
	
	// Remove message header
	remove_string(fdbk, H_HEADER, 1) 	// Removing HEADER
	fdbk = left_string(fdbk, 21) 		// Removing FOOTER
	
	// Get message type
	type = fdbk[1]
	
	// Set error variable to be empty
	error = ''
	
	switch (type)
	{
		case MT_RESPONSE:
		{
			// Remove message type
			remove_string(fdbk, MT_RESPONSE, 1)
			
			if (lastSentCmdType == MT_REQUEST) // ignore answers from succesfully sent control command
			{
				switch (left_string(fdbk, 4))
				{
					case CMD_POWER:
					{
						switch (right_string(fdbk, 16))
						{
							case POWER_OFF: 	_power = false
							case POWER_ON: 		_power = true
							case RES_ERROR: 	error = 'getPowerStatus returned an error'
						}
					}
					
					case CMD_INPUT:
					{
						switch (right_string(fdbk, 16))
						{
							case INPUT_HDMI1:	_input = 'hdmi1'
							case INPUT_HDMI2:	_input = 'hdmi2'
							case INPUT_HDMI3:	_input = 'hdmi3'
							case INPUT_HDMI4:	_input = 'hdmi4'
							case INPUT_MIRROR:	_input = 'cast'
							case INPUT_TNT:		_input = 'tnt'
							case RES_ERROR:		_input = 'app'
						}
					}
					
					case CMD_VOLUME:
					{
						switch (right_string(fdbk, 1))
						{
							case 'F': break
							default:
							{
								_volume = atoi(right_string(fdbk, 3))
							}
						}
					}
					
					case CMD_MUTE:
					{
						switch (right_string(fdbk, 16))
						{
							case MUTE_AUDIO: 	_mute = true
							case UNMUTE_AUDIO:	_mute = false
							case RES_ERROR:		error = 'getAudioMute returned an error'
						}
					}
				}
			}
		}
		
		case MT_NOTIFY:
		{
			remove_string(fdbk, MT_NOTIFY, 1)
			
			switch (left_string(fdbk, 4))
			{
				// firePowerChange event
				case CMD_POWER:
				{
					switch (right_string(fdbk, 16))
					{
						case POWER_OFF: 	_power = false
						case POWER_ON: 		_power = true
					}
				}
				
				// fireInputChange event
				case CMD_INPUT:
				{
					switch (right_string(fdbk, 16))
					{
						case INPUT_HDMI1:	_input = 'hdmi1'
						case INPUT_HDMI2:	_input = 'hdmi2'
						case INPUT_HDMI3:	_input = 'hdmi3'
						case INPUT_HDMI4:	_input = 'hdmi4'
						case INPUT_MIRROR:	_input = 'cast'
						case INPUT_TNT:		_input = 'tnt'
					}
				}
				
				// fireMuteChange event
				case CMD_MUTE:
				{
					switch (right_string(fdbk, 16))
					{
						case MUTE_AUDIO: 	_mute = true
						case UNMUTE_AUDIO:	_mute = false
					}
				}
				
				// fireVolumeChange event
				case CMD_VOLUME:
				{
					switch (right_string(fdbk, 1))
					{
						case 'F': 	break
						default: 	_volume = atoi(right_string(fdbk, 3))
					}
					
				}
			}
		}
	}
	
	if (error <> '')
	{
		call 'Debug'(amx_error, "'Feedback analysis returned an error: ', error")
	}
}

define_function DirectSendCommand (char _msgType, char _cmd[4], char _data[16])
{
	local_var char _fullCmd[24]
	if (_online)
	{
		timed_wait_until(_sendingData == false) 20
		{
			_sendingData = true
			
			// Example
			// [*S]_[C_POWR_0000000000000001]_[10] = Power On
			_fullCmd = "H_HEADER, _msgType, _cmd, _data, H_FOOTER"
			
			send_string dvTV, _fullCmd
			
			call 'Debug'(amx_debug, "'Command sent: ', _fullCmd")
			
			wait 5 _sendingData = false
		}
	}
	else
	{
		call 'Debug'(amx_error, "'Could not send command to TV, status is offline !'")
	}
}

define_start

	ip_client_open(dvTV.port, ipAddr, TCP_PORT, IP_TCP)

define_event

	data_event[dvTV]
	{
		online:
		{
			_online = true
			
			timeline_create(TIMELINE_TV_ID, EVERY_30S_TIMES, 1, TIMELINE_RELATIVE, TIMELINE_REPEAT)
			
			call 'Debug'(amx_debug, "'Otomis_Sony_Bravia_IP (', ipAddr, ') - Socket opened !'")
		}
		
		onerror:
		{
			local_var char msg[80]
			
			_online = false
			
			switch (data.number)
			{
				case  1:  msg = 'invalid server address'
				case  2:  msg = 'invalid server port'
				case  3:  msg = 'invalid value for Protocol'
				case  4:  msg = 'unable to open communication port with server'
				case  6:  msg = 'connection refused'
				case  7:  msg = 'connection timed out'
				case  8:  msg = 'unknown connection error'
				case  9:  msg = 'already closed'
				case 10:  msg = 'binding error'
				case 11:  msg = 'listening error'
				case 16:  msg = 'too many open sockets'
				default:  msg = itoa(data.number)
			}
			
			call 'Debug'(amx_error, "'Otomis_Sony_Bravia_IP (', ipAddr, ') - Error: ', msg")
			wait 60 ip_client_open(dvTV.port, ipAddr, TCP_PORT, IP_TCP)
		}
		
		string:
		{
			if (find_string(data.text, '*', 1))
			{
				FeedbackAnalysis(data.text)
			}
		}

		offline:
		{
			_online = false
			ip_client_close(dvTV.port)
		}
	}
	
	data_event[vdvTV]
	{
		command:
		{
			local_var char cmd[200]
			local_var char tab[4][25]
			
			tab[1] = ''
			tab[2] = ''
			tab[3] = ''
			tab[4] = ''
			
			//send_string 0, "'DEBUG SONY: ', data.text"
			
			cmd = upper_string(data.text)
			StringSplit(cmd, ':', tab)
			
			//send_string 0, "'DEBUG SONY: ', tab[1], ' ', tab[2]"
			
			lastSentCmdType = MT_CONTROL
			
			switch (tab[1])
			{
				case 'POWER':
				{
					switch (tab[2])
					{
						case 'ON':		DirectSendCommand(MT_CONTROL, CMD_POWER, POWER_ON)
						case 'OFF':		DirectSendCommand(MT_CONTROL, CMD_POWER, POWER_OFF)
						default:		call 'Debug'(amx_error, "'Unknown power command: ', tab[2]")
					}
				}
				
				case 'VOLUME':
				{
					switch (tab[2])
					{
						case 'UP':		DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_VOLUP)
						case 'DOWN':	DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_VOLDOWN)
						case 'MUTE':	DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_VOLMUTE)
						default:		call 'Debug'(amx_error, "'Unknown volume command: ', tab[2]")
					}	
				}
				
				case 'INPUT':
				{					
					switch (tab[2])
					{
						case 'HDMI1':	DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_HDMI1)
						case 'HDMI2':	DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_HDMI2)
						case 'HDMI3':	DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_HDMI3)
						case 'HDMI4':	DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_HDMI4)
						case 'TNT':		DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_TNT)
						case 'CAST':	DirectSendCommand(MT_CONTROL, CMD_INPUT, INPUT_MIRROR)
						default:		call 'Debug'(amx_error, "'Unknown input command: ', tab[2]")
					}
				}
				
				case 'PRESET':
				{
					local_var integer _ch
					
					_ch = atoi(tab[2])
					
					if (_ch < 10)
					{
						DirectSendCommand(MT_CONTROL, CMD_IR, _channels[_ch + 1])
					}
					else if (_ch >= 10 && _ch < 100)
					{
						DirectSendCommand(MT_CONTROL, CMD_IR, _channels[((_ch - (_ch % 10)) / 10) + 1])
						wait 10 DirectSendCommand(MT_CONTROL, CMD_IR, _channels[(_ch % 10) + 1])
					}
					else
					{
						call 'Debug'(amx_error, "'Unknown preset command: ', tab[2]")
					}
				}
				
				case 'REMOTE':
				{
					if (!_power) send_command vdvTV, 'Power:On'
					
					timed_wait_until (_power) 100
					{
						switch(tab[2])
						{
							case 'UP':				DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_UP)
							case 'DOWN':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_DOWN)
							case 'LEFT':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_LEFT)
							case 'RIGHT':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_RIGHT)
							case 'OK':				DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_OK)
							case 'MENU':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_HOME)
							case 'EXIT':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_RETURN)
							case 'RETURN':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_RETURN)
							case 'CH+':				DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_CHUP)
							case 'CH-':				DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_CHDOWN)
							case 'PLAY':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_PLAY)
							case 'PAUSE':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_PAUSE)
							case 'STOP':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_STOP)
							case 'FORWARD':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_FORWARD)
							case 'REWIND':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_REWIND)
							case 'A_RED':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_RED)
							case 'B_GREEN':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_GREEN)
							case 'C_YELLOW':		DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_YELLOW)
							case 'D_BLUE':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_BLUE)
							case 'SMARTHUB':		DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_HOME)
							case 'DISPLAY':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_DISPLAY)
							case 'TOOLS':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_OPTIONS)
							case 'INFO':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_OPTIONS)
							case 'GUIDE':			;
							case 'CHLIST':			;
							case '3D':				;
							case 'ADSUB':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_SUBTITLE)
							case 'NEXT':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NEXT)
							case 'PREV':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_PREV)
							case 'ACTION':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_ACTION)
							case 'POWER_TOGGLE':	DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_POWER)
							case 'NUM_0':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_0)
							case 'NUM_1':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_1)
							case 'NUM_2':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_2)
							case 'NUM_3':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_3)
							case 'NUM_4':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_4)
							case 'NUM_5':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_5)
							case 'NUM_6':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_6)
							case 'NUM_7':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_7)
							case 'NUM_8':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_8)
							case 'NUM_9':			DirectSendCommand(MT_CONTROL, CMD_IR, REMOTE_NUM_9)
							default:				call 'Debug'(amx_error, "'Unknown remote command: ', tab[2]")		
						}
					}
				}
				
				case 'GET':
				{
					lastSentCmdType = MT_REQUEST
					
					switch (tab[2])
					{
						case 'POWER': 	DirectSendCommand(MT_REQUEST, CMD_POWER, REQ_FILL)
						case 'INPUT': 	DirectSendCommand(MT_REQUEST, CMD_INPUT, REQ_FILL)
						case 'VOLUME':	DirectSendCommand(MT_REQUEST, CMD_VOLUME, REQ_FILL)
					}
				}
				
				default:
				{
					call 'Debug'(amx_error, "'Unknown command: ', tab[1]")
				}
			}
		}
	}
	
	button_event[TPs, chCodes]
	{
		push:
		{
			if (!isProxyEnabled)
			{
				stack_var integer _btn
				
				_btn = get_last(chCodes)
				
				call 'Debug'(amx_info, "'Button pushed on TP(', itoa(button.input.device.number),'): ', itoa(button.input.channel)")
				
				select
				{
					// TNT Presets
					active (_btn <= 35):	send_command vdvTV, "'PRESET:', itoa(_btn)"
					
					// Remote control
					active (_btn == 36):	send_command vdvTV, 'REMOTE:UP'
					active (_btn == 37):	send_command vdvTV, 'REMOTE:DOWN'
					active (_btn == 38):	send_command vdvTV, 'REMOTE:LEFT'
					active (_btn == 39):	send_command vdvTV, 'REMOTE:RIGHT'
					active (_btn == 40):	send_command vdvTV, 'REMOTE:OK'
					active (_btn == 41):	send_command vdvTV, 'REMOTE:HOME'
					active (_btn == 42):	send_command vdvTV, 'REMOTE:RETURN'
					active (_btn == 43):	send_command vdvTV, 'REMOTE:CH+'
					active (_btn == 44):	send_command vdvTV, 'REMOTE:CH-'
					active (_btn == 45):	send_command vdvTV, 'REMOTE:PLAY'
					active (_btn == 46):	send_command vdvTV, 'REMOTE:PAUSE'
					active (_btn == 47):	send_command vdvTV, 'REMOTE:STOP'
					active (_btn == 48):	send_command vdvTV, 'REMOTE:NEXT'
					active (_btn == 49):	send_command vdvTV, 'REMOTE:PREV'
					active (_btn == 50):	send_command vdvTV, 'REMOTE:FORWARD'
					active (_btn == 51):	send_command vdvTV, 'REMOTE:REWIND'
					active (_btn == 52):	send_command vdvTV, 'REMOTE:RED'
					active (_btn == 53):	send_command vdvTV, 'REMOTE:GREEN'
					active (_btn == 54):	send_command vdvTV, 'REMOTE:BLUE'
					active (_btn == 55):	send_command vdvTV, 'REMOTE:YELLOW'
					active (_btn == 56):	send_command vdvTV, 'REMOTE:OPTIONS'
					active (_btn == 57):	send_command vdvTV, 'REMOTE:SUBTITLE'
					active (_btn == 58):	send_command vdvTV, 'REMOTE:ACTION'
					active (_btn == 59):	send_command vdvTV, 'REMOTE:NUM_0'
					active (_btn == 60):	send_command vdvTV, 'REMOTE:NUM_1'
					active (_btn == 61):	send_command vdvTV, 'REMOTE:NUM_2'
					active (_btn == 62):	send_command vdvTV, 'REMOTE:NUM_3'
					active (_btn == 63):	send_command vdvTV, 'REMOTE:NUM_4'
					active (_btn == 64):	send_command vdvTV, 'REMOTE:NUM_5'
					active (_btn == 65):	send_command vdvTV, 'REMOTE:NUM_6'
					active (_btn == 66):	send_command vdvTV, 'REMOTE:NUM_7'
					active (_btn == 67):	send_command vdvTV, 'REMOTE:NUM_8'
					active (_btn == 68):	send_command vdvTV, 'REMOTE:NUM_9'
					active (_btn == 69):	send_command vdvTV, 'REMOTE:POWER_TOGGLE'
				}
			}
		}
		
		hold[3, repeat]:
		{
			if (!isProxyEnabled)
			{
				stack_var integer _btn
				
				_btn = get_last(chCodes)
				
				call 'Debug'(amx_info, "'Button held on TP(', itoa(button.input.device.number),'): ', itoa(button.input.channel)")
				
				select
				{
					// Remote control
					active (_btn == 36):	send_command vdvTV, 'REMOTE:UP'
					active (_btn == 37):	send_command vdvTV, 'REMOTE:DOWN'
					active (_btn == 38):	send_command vdvTV, 'REMOTE:LEFT'
					active (_btn == 39):	send_command vdvTV, 'REMOTE:RIGHT'
					active (_btn == 43):	send_command vdvTV, 'REMOTE:CH+'
					active (_btn == 44):	send_command vdvTV, 'REMOTE:CH-'
				}
			}
		}
	}
	
	timeline_event[TIMELINE_TV_ID]
	{
		if (_online)
		{
			send_command vdvTV, 'GET:POWER'
			
			if (_power)
			{
				wait 10 send_command vdvTV, 'GET:VOLUME'
				wait 20 send_command vdvTV, 'GET:INPUT'
			}
		}
	}
