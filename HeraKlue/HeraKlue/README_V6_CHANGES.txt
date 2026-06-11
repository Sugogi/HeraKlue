Heraklue Optimized Swift Files v6

Changes in this version:
- Poseidon and Ariadne now use ground-based anchoring.
- Character anchors use horizontal camera direction only, so models stay upright instead of inheriting camera pitch.
- Poseidon still spawns farther away at about 3.2 meters.
- Ariadne still keeps the 180-degree Y rotation so she faces the user.
- Removed all automatic scene advancement. Scenes now advance only by user tap.
- Parent consent and Ariadne welcome screens no longer auto-advance after 5 seconds.
- Removed delayed initial AR scene placement.

Important Xcode reminder:
- Make sure Poseidon_Stylized.usdz and Ariadne_Stylized.usdz have Target Membership checked.
