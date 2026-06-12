Heraklue v10 changes

1. Removed the AR fountain placeholder.
   - ARModelType.lionFountain was removed.
   - Journey steps that referenced the fountain now use .none, so no fountain AR object appears.

2. Added crosshair speaker targeting for bottom dialogue.
   - Bottom story text for speaker dialogue only appears when the center crosshair is aimed at the correct speaker.
   - Ariadne dialogue requires the crosshair to hit Ariadne.
   - Poseidon dialogue requires the crosshair to hit Poseidon.
   - Tapping to advance speaker dialogue now also requires the correct speaker to be targeted.

3. Added RealityKit focus hitboxes.
   - Poseidon, Ariadne, and the puzzle piece now get invisible collision hitboxes so crosshair targeting is easier.
   - These hitboxes are only for interaction detection and do not render visually.

4. Preserved earlier behavior.
   - Poseidon remains persistent after first spawning.
   - Ariadne remains persistent after being revealed by the marker.
   - Puzzle piece still spawns upright after scanning the marker.
   - Marker scan gating remains active after the mission starts.
   - Scene progression remains tap only.

Important Xcode reminder:
Make sure these files have Target Membership checked:
- Poseidon_Stylized.usdz
- Ariadne_Stylized.usdz
- ar_marker.jpg
