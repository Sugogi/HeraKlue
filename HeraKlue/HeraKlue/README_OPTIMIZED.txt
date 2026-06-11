Heraklue Optimized Swift Files v5

Changes in this version:
- Poseidon now spawns about 3.2 meters in front of the user's camera instead of close to the user.
- Poseidon keeps the stable anchor behavior from v3/v4, so he does not jump while the player advances through Poseidon dialogue scenes.
- Poseidon's far scene scale was increased so he remains visible even though he starts farther away.
- Ariadne_Stylized.usdz is rotated 180 degrees around the Y axis so she faces the user.
- Ariadne placeholder fallback is also rotated 180 degrees.

Install:
1. Replace the matching Swift files in Xcode.
2. Keep Poseidon_Stylized.usdz and Ariadne_Stylized.usdz in the project.
3. Make sure both USDZ files have Target Membership checked for the app target.
4. Build and run on a real ARKit compatible device.
