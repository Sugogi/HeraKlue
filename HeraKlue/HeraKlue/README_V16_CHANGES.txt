V16 changes
===========

- Ariadne now spawns 1 meter away from the scanned mission marker instead of directly on the marker.
- The spawn direction is from the marker toward the user's camera, with Ariadne grounded and facing the user.
- The puzzle piece now spawns at the same time as Ariadne.
- The puzzle piece appears above Ariadne's head and stays upright.
- Ariadne and the puzzle piece share the persistent marker scene, so the later puzzle-piece step will not create a duplicate separate puzzle piece.
- Existing behavior is preserved: Poseidon spawns during the Ariadne tutorial, stays persistent, Poseidon dialogue requires aim and proximity, and mission/objective prompts remain separate from dialogue.
