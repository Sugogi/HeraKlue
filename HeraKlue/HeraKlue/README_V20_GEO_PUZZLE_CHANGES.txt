Heraklue Optimized Swift Files v20

Changes in this version:
- Removed the required reference marker flow for the first puzzle mission.
- Added GPS based puzzle spawning at 35.3416° N, 25.1319° E.
- The AR session now uses gravityAndHeading alignment so the geographic target can be projected in the correct compass direction.
- The puzzle piece appears when the user is within about 35 meters of the target coordinate.
- After the mission has been active for about 45 seconds, the app shows a help prompt.
- If the user presses the button while the help prompt is shown, Ariadne is requested as a guide.
- Ariadne then spawns near the puzzle piece location to guide the player.
- Poseidon still spawns during the Ariadne tutorial and remains persistent.
- Audio support from v19 is preserved.

Important Xcode setup:
1. Add this key to Info.plist or the app will not be allowed to access location:
   NSLocationWhenInUseUsageDescription
   Example value: HeraKlue uses your location to place AR puzzle pieces at real world mission sites.

2. Make sure these files have Target Membership checked and are included in Build Phases > Copy Bundle Resources:
   Poseidon_Stylized.usdz
   Ariadne_Stylized.usdz
   all .mp3 files

Notes:
- GPS is not exact. The activation radius is intentionally set to about 35 meters to handle outdoor GPS drift.
- When the player is very close to the coordinate, the puzzle piece is placed slightly in front of the camera so it remains visible.
- The old ar_marker.jpg can remain in the project, but it is no longer required for this mission flow.
