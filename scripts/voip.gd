extends AudioStreamPlayer

signal packet_sent
signal packet_received

const MIN_PACKET_LENGTH = 1

var mic : AudioEffectRecord
var record
var recording = false
var was_recording = false
var time_elapsed = 0
var receive_buffer = Dictionary()
var logger
var opusEncoder
var opusDecoder

func _ready():
	mic = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"), 0)
	if ! mic:
		assert(false, 
			"No AudioServer bus has been detected with the name 'Record'" +  
			" and the effect 'AudioRecordEffect'.\n" +
			"You can check /addons/adrenesis.opusLobby/default_bus_layout.tres for an example.\n" +
			"Check your project setting (under Audio) to set default audio bus layout.")
	logger = get_node("../OpusLobbyDisplayer/LoggerContainer/ScrollContainer/Log")
	opusEncoder = get_node("../OpusEncoder")
	opusDecoder = get_node("../OpusDecoder")

remote func _play(id, opusPackets, format, mix_rate, stereo):
	emit_signal("packet_received", id)
	# Decode the incoming packets into raw PCM data
	var pcmData = opusDecoder.decode(opusPackets)
	var audioStream = AudioStreamSample.new()
	audioStream.data = pcmData
	audioStream.set_format(format)
	audioStream.set_mix_rate(mix_rate)
	audioStream.set_stereo(stereo)
	var audioStreamPlayer = get_node('Player' + str(id) + 'Output')
	audioStreamPlayer.stream = audioStream
	audioStreamPlayer.play()
		
func _process(delta: float) -> void:
	if time_elapsed >= MIN_PACKET_LENGTH or (was_recording and not recording) :
		record = mic.get_recording()
		mic.set_recording_active(false)
		mic.set_recording_active(true)
		var pcmData = record.get_data()
		# Encode the raw PCM data to a stream of Opus Packets
		var opusEncoded = opusEncoder.encode(pcmData)
		rpc_unreliable("_play",get_tree().get_network_unique_id(), opusEncoded, record.get_format(), record.get_mix_rate(), record.is_stereo())
		emit_signal("packet_sent", [ record.get_data().size() ] )
		time_elapsed = 0
	if recording:
		if mic.is_recording_active():
			time_elapsed += delta
		else:
			time_elapsed = 0
			mic.set_recording_active(true)
	else:
		mic.set_recording_active(false)
	was_recording = recording
