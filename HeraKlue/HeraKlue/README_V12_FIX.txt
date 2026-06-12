V12 compile fix

Fixed ContentView.swift switch exhaustiveness error by changing the optional ARFocusTarget switch to explicit Optional cases:
- .some(.ariadne)
- .some(.poseidon)
- .some(.puzzlePiece)
- .some(.none), .none

No behavior changes were made beyond this compile fix.
