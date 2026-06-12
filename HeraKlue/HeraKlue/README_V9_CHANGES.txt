Heraklue v9 changes

1. Removed the in-story Button Tutorial scene.
   - Removed the welcome_button_features story step.
   - Removed the unused headset diagram model case and helper function.

2. Made the scanned puzzle piece upright.
   - The puzzle piece still appears after the mission starts and the marker is scanned.
   - It is rotated 90 degrees around the X axis so it stands vertically instead of lying flat.

3. Made Ariadne persistent after her hints.
   - Ariadne now uses a separate persistent anchor after she is revealed by the scanned marker.
   - Puzzle piece scenes no longer remove Ariadne.
   - Poseidon remains persistent too.

Assets that must have target membership checked in Xcode:
- Poseidon_Stylized.usdz
- Ariadne_Stylized.usdz
- ar_marker.jpg
