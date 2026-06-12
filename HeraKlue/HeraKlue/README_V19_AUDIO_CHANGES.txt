Heraklue Optimized Swift Files v19

Changes in this version:
- Added uploaded MP3 voice files into the project package.
- Added audioFileName support to ARStoryStep.
- Replaced text-to-speech-only playback with bundled MP3 playback and text-to-speech fallback.
- Added AVAudioSession playback setup so audio is more reliable on device.
- Onboarding, dialogue, selected mission prompts, Ariadne guide lines, and Poseidon lines can now play matching MP3 files.
- Kept v18 behavior: Poseidon starts during Ariadne tutorial, Poseidon stays persistent, Ariadne stays until the mission is accepted, marker-gated Ariadne/puzzle behavior is preserved.

Important Xcode setup:
1. Drag every .mp3 file into the Xcode project if it is not already there.
2. Check Target Membership for every .mp3 file.
3. In Build Phases > Copy Bundle Resources, confirm every .mp3 file is listed.
4. Keep Poseidon_Stylized.usdz, Ariadne_Stylized.usdz, and ar_marker.jpg in Copy Bundle Resources too.

Audio lookup uses the exact MP3 file names, so do not rename the files unless you also update audioFileName in ARStoryStep.swift.
