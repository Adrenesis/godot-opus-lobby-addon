# godot-opus-lobby-addon
A separate repository for Opus lobby addon for better use with git submodule

You can check the full demo of the addon here:
https://github.com/Adrenesis/libopus-gdnative-voip-demo

## Credits
Thanks to Wavesonics for:
https://github.com/Godot-Opus/libopus-gdnative-voip-demo

Thanks to casbrugman for:
https://github.com/casbrugman/godot-voip-demo

## Displayer
This addons features an interface allowing to have sound of each player on separate audio bus, with settings for each player, a textual chat, an audio device panel, and an overlay to keep track of the players.

Those window can be used with predefined activable InputMap (in Project>>Controls) action shortcuts:
"ui_opus_lobby_push_to_talk" (default key: V (like Voice)) <br>
"ui_opus_lobby_show_advanced_panel_settings" (default key: Shift + O (like Super Overlay)) <br>
"ui_opus_lobby_show_overlay" (default key: O (like Overlay)) <br>
"ui_opus_lobby_show_logger" (default key: Y (like in the ol' tymes)) <br>
"ui_opus_lobby_show_server_settings" (default key: U (like SUrvers, no I don't know, it happened to be just in between the others and rarely used)) <br>
"ui_opus_lobby_show_device_settings" (default key: Shift + U (leave me alone)) <br>

## Multithread
The voice netcode is mostly multithread and shouldn't trigger any framedrops whatsoever

## Voice netcode:
This app shows a netcode thingy for vocal servers, it has some exported variable to be messed with (in OpusLobby.tscn>>Output Node), I just took the time to find something hearable but it is definetly customisable.

The netcode has a packet queue to avoid skipping parts, it also records all the time to catchup with audio drivers delay.

It also use two RecordEffect, to avoid any cuts between packets by manipulation both effects and over recording (recording for more than expected for one packet time) a bit.

## Addon usage
```
Autoload Setup:
    Go to project settings
    Go to Autoload Tab and load "/addons/adrenesis.opusLobby/Network.gd"
```

```
Audio Bus Setup:
    Go to Audio Bottom Panel
    Add an AudioBus named "RecordLoopback"
    Redirect that bus to "Master"
    Add an AudioBus named "Record"
    Redirect that bus to RecordLoopBack
    Mute RecordLoopBack for user's comfort :P
```

## Known Issues:


##### AudioEffectRecord Stability and linux race condition

It isn't stable in default godot build as AudioRecordEffect is glitched and is being fixed up in godot issues at: <br>
https://github.com/godotengine/godot/issues/34494#issuecomment-679106012 <br>
Therefore should be build with either:
mika314's fix (found at: https://github.com/godotengine/godot/pull/36569/commits) <br>
or ours (found at: https://github.com/Adrenesis/godot/tree/audio-fix-get-recording-cowdata) <br>
you can also get more functional branch for this by getting another one of ours (found at: https://github.com/Adrenesis/godot/tree/3.2-all-audio-fixes) <br> which fixes that, a race condition for linux monkeyfixed by some long print at init, and add get_recording_size to avoid outputing useless errors.

##### Multithread

It is probably not stable and it is not fully multithreaded (thinking about some modules for that), there is some code to avoid that but this is still pretty new to me.