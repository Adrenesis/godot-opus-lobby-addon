extends AudioStreamPlayer

signal packet_sent
signal packet_received

export(float) var packet_length = 0.200
export(float) var loop_begin = 0.1
export(float) var over_record_length = 0.6

var mic : AudioEffectRecord
var mic1 : AudioEffectRecord
var record
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
var lastRecord
var currentRecord
var holding_packet = false
var taking_final_packet = false
var timeSinceLastPacketRecorded : float = 0
var precapture_done = false

func _ready():
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

remote func _receive_packet(id : int, opusPackets, format, mix_rate, stereo):
	emit_signal("packet_received", id)
	# Decode the incoming packets into raw PCM data
	var pcmData = opusDecoder.decode(opusPackets)
	var audioStream = AudioStreamSample.new()
	audioStream.data = pcmData
	audioStream.set_format(format)
	audioStream.set_mix_rate(mix_rate)
	audioStream.set_stereo(stereo)
	if not receive_buffer.has(id):
		receive_buffer[id] = []
		time_since_last_packet_played[id] = 10.0
	receive_buffer[id].push_back(audioStream)

func _play(id, audioStream):
	var audioStreamPlayer = get_node('Player' + str(id) + 'Output')
	audioStreamPlayer.stream = audioStream
	audioStreamPlayer.play(packet_length * loop_begin)
		
func _process(delta: float) -> void:
	#active mic1
	#take record of mic
	#disable mic
	# mic1 = mic
	if time_elapsed >= packet_length * (1.0 - over_record_length) and not precapture_done:
		mic1.set_recording_active(true)
		precapture_done = true
	if time_elapsed >= packet_length:
		record = mic.get_recording()
		mic.set_recording_active(false)
		var mic_temp = mic
		mic = mic1
		mic1 = mic_temp
		var pcmData = record.get_data()
		# Encode the raw PCM data to a stream of Opus Packets
		var opusEncoded = opusEncoder.encode(pcmData)
		lastPacket = currentPacket
		lastRecord = currentRecord
		currentPacket = opusEncoded
		currentRecord = record
		precapture_done = false
		time_elapsed = 0
	if (not was_recording and recording) and lastPacket and lastRecord:
		taking_final_packet = false
		holding_packet = false
		if lastRecord:
			rpc("_receive_packet",get_tree().get_network_unique_id(), lastPacket, lastRecord.get_format(), lastRecord.get_mix_rate(), lastRecord.is_stereo())
			emit_signal("packet_sent", [ lastRecord.get_data().size() ] )
			lastRecord = null
			lastPacket = null
		if currentRecord:
			rpc("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecord.get_format(), currentRecord.get_mix_rate(), currentRecord.is_stereo())
			emit_signal("packet_sent", [ currentRecord.get_data().size() ] )
			currentRecord = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if (recording and timeSinceLastPacketRecorded >= packet_length):
		if currentRecord:
			rpc("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecord.get_format(), currentRecord.get_mix_rate(), currentRecord.is_stereo())
			emit_signal("packet_sent", [ currentRecord.get_data().size() ] )
			currentRecord = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if(was_recording and not recording) or taking_final_packet or holding_packet:
		if timeSinceLastPacketRecorded >= packet_length:
			if currentRecord:
				rpc("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecord.get_format(), currentRecord.get_mix_rate(), currentRecord.is_stereo())
				emit_signal("packet_sent", [ currentRecord.get_data().size() ] )
				currentRecord = null
				currentPacket = null
			holding_packet = false
			taking_final_packet = not taking_final_packet
			timeSinceLastPacketRecorded = 0
		else:
			holding_packet = true
	if mic.is_recording_active():
		time_elapsed += delta
#		print("pouet")
	else:
		time_elapsed = 0
#	var key : int
	for key in receive_buffer.keys():
		time_since_last_packet_played[key] += delta
		if time_since_last_packet_played[key] >= packet_length:
			if receive_buffer[key].size() >= 1:
				var playback_speed = 1.0 + receive_buffer[key].size() * 0.05
				var output = get_node('Player' + str(key) + 'Output')
				var busId = AudioServer.get_bus_index("Player" + str(key))
				var effect : AudioEffectPitchShift = AudioServer.get_bus_effect(busId, 0)
				output.pitch_scale = playback_speed
				effect.pitch_scale = 1.0 / playback_speed
				_play(key, receive_buffer[key].pop_front())
				time_since_last_packet_played[key] = 0
			
			
#			mic.set_recording_active(true)
		
#		mic.set_recording_active(false)
		pass
	timeSinceLastPacketRecorded += delta

	was_recording = recording
