extends AudioStreamPlayer

signal packet_sent
signal packet_received

export(float) var packet_length = 0.200
export(float) var loop_begin = 0.1
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
var lastRecord
var currentRecord
var holding_packet = false
var taking_final_packet = false
var timeSinceLastPacketRecorded : float = 0
var precapture_done = false
var currentRecordInfo = Dictionary()
var lastRecordInfo = Dictionary()

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
	var audioStream = AudioStreamSample.new()
	audioStream.data = opusDecoder.decode(opusPackets)
	audioStream.set_format(format)
	audioStream.set_mix_rate(mix_rate)
	audioStream.set_stereo(stereo)
	# Emulate packet to test memory leaks on rpc
#	var data : PoolByteArray = PoolByteArray()
#	print(int(44100 * packet_length))
#	data.resize(int(44100 * packet_length * 4 ))
#	for i in range(data.size()):
#		data[i] = rand_range(-32768, 32768)
#	print(data.size())
#	audioStream = AudioStreamSample.new()
#	audioStream.mix_rate = 44100
#	audioStream.stereo = true
#	audioStream.format = AudioStreamSample.FORMAT_16_BITS
#	audioStream.set_data(data)
	if not receive_buffer.has(id):
		time_since_last_packet_played[id] = 10.0
		receive_buffer[id] = []
	receive_buffer[id].push_back(audioStream)
	opusPackets = null

func _play(id, audioStream):
	var audioStreamPlayer = get_node('Player' + str(id) + 'Output')
	audioStreamPlayer.stream = audioStream
	audioStreamPlayer.play(packet_length * loop_begin)

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

func _process(delta: float) -> void:
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
	if (not was_recording and recording) and lastPacket and lastRecord:
		taking_final_packet = false
		holding_packet = false
		if lastRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), lastPacket, lastRecordInfo["format"], lastRecordInfo["mix_rate"], lastRecordInfo["stereo"])
			emit_signal("packet_sent", [ lastRecordInfo["size"] ] )
			lastRecordInfo = null
			lastPacket.resize(0)
			lastPacket = null
		if currentRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket.resize(0)
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if (recording and timeSinceLastPacketRecorded >= packet_length):
		if currentRecordInfo:
			rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
			emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
			currentRecordInfo = null
			currentPacket.resize(0)
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if(was_recording and not recording) or taking_final_packet or holding_packet:
		if timeSinceLastPacketRecorded >= packet_length:
			if currentRecordInfo:
				rpc_unreliable("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecordInfo["format"], currentRecordInfo["mix_rate"], currentRecordInfo["stereo"])
				emit_signal("packet_sent", [ currentRecordInfo["size"] ] )
				currentRecordInfo = null
				currentPacket.resize(0)
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
	for key in receive_buffer.keys():
		time_since_last_packet_played[key] += delta
		if time_since_last_packet_played[key] >= packet_length:
			if receive_buffer[key].size() >= 1:
				var playback_speed = 1.0 + receive_buffer[key].size() * 0.05
				var output = get_node('Player' + str(key) + 'Output')
				var busId = AudioServer.get_bus_index("Player" + str(key))
				var effect : AudioEffectPitchShift = AudioServer.get_bus_effect(busId, 0)
				if output:
					output.pitch_scale = playback_speed
				if effect:
					effect.pitch_scale = 1.0 / playback_speed
				_play(key, receive_buffer[key].pop_front())
				time_since_last_packet_played[key] = 0

	timeSinceLastPacketRecorded += delta

	was_recording = recording
