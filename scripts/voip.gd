extends AudioStreamPlayer

signal packet_sent
signal packet_received

const MIN_PACKET_LENGTH = 0.180

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
		time_since_last_packet_played[id] = MIN_PACKET_LENGTH
	receive_buffer[id].push_back(audioStream)

func _play(id, audioStream):
	var audioStreamPlayer = get_node('Player' + str(id) + 'Output')
	audioStreamPlayer.stream = audioStream
	audioStreamPlayer.play()
		
func _process(delta: float) -> void:
	#active mic1
	#take record of mic
	#disable mic
	# mic1 = mic
	if time_elapsed >= MIN_PACKET_LENGTH * 0.9:
		mic1.set_recording_active(true)
	if time_elapsed >= MIN_PACKET_LENGTH:
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
	if (recording and timeSinceLastPacketRecorded >= MIN_PACKET_LENGTH):
		if currentRecord:
			rpc("_receive_packet",get_tree().get_network_unique_id(), currentPacket, currentRecord.get_format(), currentRecord.get_mix_rate(), currentRecord.is_stereo())
			emit_signal("packet_sent", [ currentRecord.get_data().size() ] )
			currentRecord = null
			currentPacket = null
		timeSinceLastPacketRecorded = 0
	if(was_recording and not recording) or taking_final_packet or holding_packet:
		if timeSinceLastPacketRecorded >= MIN_PACKET_LENGTH:
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
		if time_since_last_packet_played[key] >= MIN_PACKET_LENGTH:
			if receive_buffer[key].size() >= 1:
				var playback_speed : float = 1.0 + 0.05 * (receive_buffer[key].size()-1)
				var busId : int = AudioServer.get_bus_index("Player" + str(key))
				var effect : AudioEffectPitchShift = AudioServer.get_bus_effect(busId, 0)
				var output = get_node("Player" + str(key) + "Output")
				output.pitch_scale = playback_speed
				effect.pitch_scale = 1.0 / playback_speed
				_play(key, receive_buffer[key].pop_front())
			
			
#			mic.set_recording_active(true)
		
#		mic.set_recording_active(false)
		pass
	timeSinceLastPacketRecorded += delta

	was_recording = recording
