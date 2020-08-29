extends AudioStreamPlayer

signal packet_sent
signal packet_received
signal audio_buses_changed
signal packet_to_send(id, packet, format, mixrate, stereo)

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
var players_stream := Dictionary()
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
	if not Network.is_connected("player_connected", self, "_create_audio_bus_and_stream_player"):
		Network.connect("player_connected", self, "_create_audio_bus_and_stream_player")
	if not Network.is_connected("player_disconnected", self, "_destroy_audio_bus_and_stream_player"):
		Network.connect("player_disconnected", self, "_destroy_audio_bus_and_stream_player")
	if not self.is_connected("packet_to_send", self, "send_packet"):
		self.connect("packet_to_send", self, "send_packet")
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Record"), AudioEffectRecord.new(), 0)
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Record"), AudioEffectRecord.new(), 1)
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
	

func shutdown():

	thread_record_active = false
	thread_read_active = false
	recordThread.wait_to_finish()
	readThread.wait_to_finish()
	mic.set_recording_active(false)
	mic1.set_recording_active(false)
	mic = null
	mic1 = null
	AudioServer.remove_bus_effect(AudioServer.get_bus_index("Record"), 0)
	AudioServer.remove_bus_effect(AudioServer.get_bus_index("Record"), 0)
	if Network.is_connected("player_connected", self, "_create_audio_bus_and_stream_player"):
		Network.disconnect("player_connected", self, "_create_audio_bus_and_stream_player")
	if Network.is_connected("player_disconnected", self, "_destroy_audio_bus_and_stream_player"):
		Network.disconnect("player_disconnected", self, "_destroy_audio_bus_and_stream_player")

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		shutdown()
		queue_free() # default behavior


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

func send_packet(id, packet, format, mixrate, stereo):
	rpc_unreliable("_receive_packet", id, packet, format, mixrate, stereo)

func _send_record():
	if (not was_recording and recording) and lastPacket and lastRecordInfo:
		taking_final_packet = false
		holding_packet = false
		if lastRecordInfo:
#			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), lastPacket, lastRecordInfo["format"], lastRecordInfo["mix_rate"], lastRecordInfo["stereo"])
			emit_signal("packet_to_send", get_tree().get_network_unique_id(), lastPacket, lastRecordInfo["format"], lastRecordInfo["mix_rate"], lastRecordInfo["stereo"])
			emit_signal("packet_sent", [ lastRecordInfo["size"] ] )
			lastRecordInfo = null
			lastPacket = null
		if currentRecordInfo:
			emit_signal("packet_to_send", get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
#			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if (recording and timeSinceLastPacketRecorded >= packet_length):
		if currentRecordInfo:
#			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_to_send", get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if(was_recording and not recording) or taking_final_packet or holding_packet:
		if timeSinceLastPacketRecorded >= packet_length:
			if currentRecordInfo:
#				rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
				emit_signal("packet_to_send", get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
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
#		if Network.is_online():
#			_send_record()


############### READ THRAD

func _play(id, audioStream):
	if not players_stream.has(id):
		return
	var audioStreamPlayer = players_stream[id]
	if audioStreamPlayer:
		audioStream.data = opusDecoder.decode(audioStream.data)
		audioStreamPlayer.set_deferred("stream", audioStream)
		audioStreamPlayer.call_deferred("play", packet_length * loop_begin)
		# todo: find what to do

func _read_received_packets(delta):
	for key in receive_buffer.keys():
		readMutex.lock()
		time_since_last_packet_played[key] += delta
		if time_since_last_packet_played[key] >= packet_length:
			if receive_buffer[key].size() >= 1:
				var playback_speed = 1.0 + (receive_buffer[key].size() - 1) * 0.05
				if not players_stream.has(key):
					readMutex.unlock()
					continue
				var output = players_stream[key]
				var busId = AudioServer.get_bus_index("Player" + str(key))
				if busId == -1:
					readMutex.unlock()
					continue
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

# Move to signal listener
func _create_audio_bus_and_stream_player(_id, _nickname):
	var _name : String = "Player" + str(_id)
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, _name)
	AudioServer.add_bus_effect(AudioServer.get_bus_count() - 1, AudioEffectPitchShift.new(), 0)
	AudioServer.set_bus_send(AudioServer.get_bus_count() - 1, "Master")
	var audioStreamPlayer = AudioStreamPlayer.new()
	audioStreamPlayer.stream = AudioStreamSample.new()
	audioStreamPlayer.autoplay = true
	audioStreamPlayer.bus = _name
	audioStreamPlayer.name = _name + "Output"
	players_stream[_id] = audioStreamPlayer
	emit_signal("audio_buses_changed")
	add_child(audioStreamPlayer)
	

func _destroy_audio_bus_and_stream_player(_id, _nickname):
	var _name : String = "Player" + str(_id)
	var _busId = AudioServer.get_bus_index(_name)
	if _busId != -1:
		AudioServer.remove_bus(AudioServer.get_bus_index(_name))
	var audioStreamPlayer : AudioStreamPlayer
	if not players_stream.has(_name):
		if has_node(_name + "Output"):
			audioStreamPlayer = get_node(_name + "Output")
	else:
		audioStreamPlayer = players_stream[_name]
	if audioStreamPlayer:
		audioStreamPlayer.queue_free()
	players_stream[_name] = null
	emit_signal("audio_buses_changed")

remote func _receive_packet(id : int, opusPackets, format, mix_rate, stereo):
	if not opusPackets:
		return
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
#	opusPackets = null
	readMutex.unlock()
	
func _process(delta: float) -> void:
#	_record()
	if Network.is_online():
		_send_record()
#	time_elapsed += delta
#	timeSinceLastPacketRecorded += delta
#	_read_received_packets()
	pass





