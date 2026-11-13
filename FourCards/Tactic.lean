import FourCards.Game

/-!
# Tactics

A tactic decides which card a player gives away in an exchange. Every tactic is described by
the set of positions it is willing to give; the card is then drawn uniformly from that set.
-/

namespace FourCards

inductive Tactic where
  /-- Any card. -/
  | random
  /-- A card of the kind held the fewest times. This is what the AI players do. -/
  | leastCommon
  /-- Collect the given rank: never give a card of it away, give any other card. -/
  | keepRank (rank : Nat)
  deriving Repr, DecidableEq, Inhabited

namespace Tactic

/-- Positions in the hand the tactic may give away. Never empty for a non-empty hand. -/
def candidates (tactic : Tactic) (hand : Hand) : Array Nat :=
  let all := Array.range hand.size
  match tactic with
  | random => all
  | leastCommon => leastCommonIndices hand
  | keepRank rank =>
    let others := all.filter fun i => hand[i]!.rank != rank
    -- Only a complete set has no other card, and then the game is already over.
    if others.isEmpty then all else others

/-- The position of the card to give away, drawn uniformly from the candidates. -/
def choose (tactic : Tactic) (hand : Hand) : IO Nat := do
  let options := tactic.candidates hand
  return options[← IO.rand 0 (options.size - 1)]!

end Tactic

section Tests

private def c (rank : Nat) : Card := { rank, suit := .spades }

#guard Tactic.random.candidates #[c 0, c 0, c 1, c 2] == #[0, 1, 2, 3]
#guard Tactic.leastCommon.candidates #[c 0, c 0, c 1, c 2] == #[2, 3]
#guard (Tactic.keepRank 0).candidates #[c 1, c 0, c 2, c 0] == #[0, 2]
#guard (Tactic.keepRank 0).candidates #[c 0, c 0, c 2, c 0] == #[2]
#guard (Tactic.keepRank 0).candidates #[c 1, c 1, c 2, c 3] == #[0, 1, 2, 3]

end Tests

end FourCards
