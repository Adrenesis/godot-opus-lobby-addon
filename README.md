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
This addons features an interface allowing to have sound of each player on separate audio bus, with settings for each player and the textual chat.

## Addon usage
```
Autoload Setup:
    Go to project settings
    Go to Autoload and load "/addons/adrenesis.opusLobby/Network.gd"
```

```
Audio Bus Setup:
    Go to Audio Bottom Panel
    Add an AudioBus named "RecordLoopback"
    Redirect that bus to "Master"
    Add an AudioBus named "Record"
    Add an AudioMicrophoneEffect on it
    Redirect that bus to RecordLoopBack
```
