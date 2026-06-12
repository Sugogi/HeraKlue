HeraKlue v11 changes

1. Ariadne and Poseidon are normalized to about 2 meters tall when their USDZ models load.
2. Poseidon and Ariadne still use persistent anchors from the prior builds.
3. Speaker dialogue remains crosshair gated. Ariadne dialogue only appears when the crosshair is aimed at Ariadne, and Poseidon dialogue only appears when aimed at Poseidon.
4. Mission prompts and objective updates are now a different HUD style from dialogue bubbles.
5. Mission prompts and objective updates are not dependent on aiming at Ariadne or Poseidon.
6. Dialogue interaction prompts stay visible as a separate HUD pill, so the player knows when to aim at a speaker or press the button.
7. Remaining fountain wording was changed to Four Stone Lions.

Main files changed:
- ContentView.swift
- ARViewContainer.swift
- ARStoryStep.swift

Required target membership:
- Poseidon_Stylized.usdz
- Ariadne_Stylized.usdz
- ar_marker.jpg
