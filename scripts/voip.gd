extends AudioStreamPlayer

signal packet_sent
signal packet_received

export(float) var packet_length = 0.200
export(float) var loop_begin = 0.2
export(float) var over_record_length = 0.6

var mic : AudioEffectRecord
var mic1 : AudioEffectRecord
var recording = false
var was_recording = false
var time_elapsed = 0
var receive_buffer = Dictionary()
var time_since_last_packet_played = Dictionary()
var logger
var opusEncoder
var opusDecoder
var lastPacket
var currentPacket
var holding_packet = false
var taking_final_packet = false
var timeSinceLastPacketRecorded : float = 0
var precapture_done = false
var currentRecordInfo = Dictionary()
var lastRecordInfo = Dictionary()

var record_thread_delay_ms = 50
var thread_record_active = true
var thread_read_active = true
var recordThread: Thread
var readThread : Thread

var readMutex : Mutex

func _ready():
	recordThread = Thread.new()
	readThread = Thread.new()
	readMutex = Mutex.new()
	mic = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"), 0)
	mic1 = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"), 1)
	if ! mic:
		assert(false, 
			"No AudioServer bus has been detected with the name 'Record'" +  
			" and the effect 'AudioRecordEffect'.\n" +
			"You can check /addons/adrenesis.opusLobby/default_bus_layout.tres for an example.\n" +
			"Check your project setting (under Audio) to set default audio bus layout.")
	
	logger = get_node("../OpusLobbyDisplayer/LoggerContainer/ScrollContainer/Log")
	opusEncoder = get_node("../OpusEncoder")
	opusDecoder = get_node("../OpusDecoder")
	mic.set_recording_active(true)
	mic.set_format(AudioStreamSample.FORMAT_16_BITS)
	recordThread.start(self, "_thread_record")
	readThread.start(self, "_thread_read_received")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		thread_record_active = false
		thread_read_active = false
		recordThread.wait_to_finish()
		readThread.wait_to_finish()
		get_tree().quit() # default behavior

func _free():
	thread_record_active = false
	thread_read_active = false
	recordThread.wait_to_finish()
	readThread.wait_to_finish()

############### RECORD THREAD

# RECORD TOOLS

func get_record_info(record, opusEncoded):
	var recordInfo = Dictionary()
	recordInfo["stereo"] = record.stereo
	recordInfo["format"] = record.format
	recordInfo["mix_rate"] = record.mix_rate
	recordInfo["size"] = opusEncoded.size()
	return recordInfo

func update_packet():
	var record
	record = mic.get_recording()
	if not record:
		return
	var opusEncoded = opusEncoder.encode(record.get_data())
	lastPacket = currentPacket
	lastRecordInfo = currentRecordInfo
	currentPacket = opusEncoded
	currentRecordInfo = get_record_info(record, opusEncoded)

# RECORD THREAD

func _record():
	if time_elapsed >= packet_length * (1.0 - over_record_length) and not precapture_done:
		mic1.set_recording_active(true)
		precapture_done = true

	if time_elapsed >= packet_length:
		update_packet()

		mic.set_recording_active(false)
		var mic_temp = mic
		mic = mic1
		mic1 = mic_temp
		precapture_done = false
		time_elapsed = 0

func _send_record():
	if (not was_recording and recording) and lastPacket and lastRecordInfo:
		taking_final_packet = false
		holding_packet = false
		if lastRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), lastPacket, lastRecordInfo["format"], lastRecordInfo["mix_rate"], lastRecordInfo["stereo"])
			emit_signal("packet_sent", [ lastRecordInfo["size"] ] )
			lastRecordInfo = null
			lastPacket = null
		if currentRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if (recording and timeSinceLastPacketRecorded >= packet_length):
		if currentRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if(was_recording and not recording) or taking_final_packet or holding_packet:
		if timeSinceLastPacketRecorded >= packet_length:
			if currentRecordInfo:
				rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
				emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
				currentRecordInfo = null
				currentPacket = null
			holding_packet = false
			taking_final_packet = not taking_final_packet
			timeSinceLastPacketRecorded = 0
		else:
			holding_packet = true
	was_recording = recording

func _thread_record(_stub):
	var old_tick = OS.get_ticks_msec()
	while(thread_record_active):
		time_elapsed += (OS.get_ticks_msec() - old_tick) / 1000.0
		timeSinceLastPacketRecorded += (OS.get_ticks_msec() - old_tick) / 1000.0
		old_tick = OS.get_ticks_msec()
		OS.delay_msec(16)
		if not thread_record_active:
			return
		_record()
		if Network.is_online():
			_send_record()


############### READ THRAD

func _play(id, audioStream):
	var audioStreamPlayer = get_node('Player' + str(id) + 'Output')
	audioStream.data = opusDecoder.decode(audioStream.data)
	audioStreamPlayer.stream = audioStream
	audioStreamPlayer.play(packet_length * loop_begin)

func _read_received_packets(delta):
	for key in receive_buffer.keys():
		readMutex.lock()
		time_since_last_packet_played[key] += delta
		if time_since_last_packet_played[key] >= packet_length:
			if receive_buffer[key].size() >= 1:
				var playback_speed = 1.0 + (receive_buffer[key].size() - 1) * 0.05
				var output = get_node('Player' + str(key) + 'Output')
				var busId = AudioServer.get_bus_index("Player" + str(key))
				var effect : AudioEffectPitchShift = AudioServer.get_bus_effect(busId, 0)
				if output:
					output.pitch_scale = playback_speed
				if effect:
					effect.pitch_scale = 1.0 / playback_speed
				_play(key, receive_buffer[key].pop_front())
				time_since_last_packet_played[key] = 0
		readMutex.unlock()

func _thread_read_received(_stub):
	var old_tick = OS.get_ticks_msec()
	while(thread_read_active):
		var delta = (OS.get_ticks_msec() - old_tick) / 1000.0
		old_tick = OS.get_ticks_msec()
		OS.delay_msec(16)
		if not thread_record_active:
			return
		_read_received_packets(delta)

############### MAIN THREAD

remote func _receive_packet(id : int, opusPackets, format, mix_rate, stereo):
	var audioStream = AudioStreamSample.new()
	emit_signal("packet_received", id)
	audioStream.data = opusPackets
	audioStream.set_format(format)
	audioStream.set_mix_rate(mix_rate)
	audioStream.set_stereo(stereo)
	readMutex.lock()
	if not receive_buffer.has(id):
		time_since_last_packet_played[id] = 10.0
		receive_buffer[id] = []
	receive_buffer[id].push_back(audioStream)
	opusPackets = null
	readMutex.unlock()
	
#func _process(delta: float) -> void:
#	_record()
#	time_elapsed += delta
#	timeSinceLastPacketRecorded += delta
#	_read_received_packets()
#	pass





