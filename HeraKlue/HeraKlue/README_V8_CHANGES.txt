V8 marker scan changes

Changed files:
- ARViewContainer.swift
- ARStoryStep.swift
- ar_marker.jpg added as a bundle resource

Behavior:
- Poseidon remains persistent and does not disappear after he first spawns.
- Mission Ariadne appearances after mission start now require scanning ar_marker.jpg.
- Puzzle piece appearances after mission start now require scanning ar_marker.jpg.
- Scanning the marker before the mission starts does not spawn Ariadne or the puzzle piece.
- Welcome Ariadne scenes before the Poseidon mission still work normally.
- Scene progression remains tap only.
- Poseidon remains ground anchored.
- Marker spawned Ariadne is placed on the ground at the marker location and faces the camera.
- Marker spawned puzzle piece appears above the ground at the marker location.

Xcode setup:
1. Drag ar_marker.jpg into the Xcode project if it is not already there.
2. Check Target Membership for ar_marker.jpg.
3. Make sure Poseidon_Stylized.usdz and Ariadne_Stylized.usdz also have Target Membership checked.
4. The code assumes the printed marker is 12 cm wide. If you print it larger or smaller, update MissionMarker.physicalWidth in ARViewContainer.swift.
