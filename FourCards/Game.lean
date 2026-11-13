import FourCards.Card

/-!
# Game logic

Players sit in a circle, each holding four cards. On exchange number `t` (counting from 0)
player `t % n` and their clockwise neighbour `(t + 1) % n` each pick one card and swap them.
Whoever holds four cards of one kind after an exchange wins.
-/

namespace FourCards

abbrev Hand := Array Card

def sortHand (hand : Hand) : Hand :=
  hand.qsort Card.lt

/-- The rank of the hand if it is a complete four of a kind. -/
def fourOfAKind? (hand : Hand) : Option Nat :=
  match hand[0]? with
  | some first =>
    if hand.size == handSize && hand.all (·.rank == first.rank) then some first.rank else none
  | none => none

/-- Indices of the players currently holding four of a kind. -/
def winners (hands : Array Hand) : Array Nat :=
  (Array.range hands.size).filter fun i => (fourOfAKind? hands[i]!).isSome

/-- The two players taking part in exchange number `turn`: a player and their clockwise
neighbour. The pair moves one seat clockwise every turn. -/
def exchangePair (players turn : Nat) : Nat × Nat :=
  (turn % players, (turn + 1) % players)

/-- Positions in the hand of the cards an AI is willing to give away: those whose kind occurs
the fewest times in the hand. All candidates share the same count, so picking a position
uniformly at random also picks uniformly among the tied kinds. -/
def leastCommonIndices (hand : Hand) : Array Nat :=
  let count (c : Card) := hand.countP (·.rank == c.rank)
  let fewest := hand.foldl (fun acc c => min acc (count c)) hand.size
  (Array.range hand.size).filter fun i => count hand[i]! == fewest

/-- Player `a` gives the card at position `i` to player `b` and receives `b`'s card at
position `j`. Each received card takes the slot of the card given away, so the other cards
keep their positions. -/
def exchange (hands : Array Hand) (a b i j : Nat) : Array Hand :=
  let cardA := hands[a]![i]!
  let cardB := hands[b]![j]!
  let hands := hands.modify a fun hand => hand.set! i cardB
  hands.modify b fun hand => hand.set! j cardA

/-- Split a deck into hands of `handSize` cards, one per player. -/
def dealFrom (cards : Array Card) (players : Nat) : Array Hand :=
  (Array.range players).map fun p => sortHand (cards.extract (p * handSize) ((p + 1) * handSize))

/-- Fisher–Yates shuffle using the global random generator. -/
def shuffle {α : Type} (xs : Array α) : IO (Array α) := do
  let mut arr := xs
  for k in [1:arr.size] do
    let i := arr.size - k
    let j ← IO.rand 0 i
    arr := arr.swapIfInBounds i j
  return arr

/-- Shuffle a fresh deck and deal it out completely. -/
def deal (players : Nat) : IO (Array Hand) := do
  return dealFrom (← shuffle (deck players)) players

section Tests

private def c (rank : Nat) (suit : Suit := .spades) : Card := { rank, suit }

-- Winning hands
#guard fourOfAKind? #[c 2 .spades, c 2 .hearts, c 2 .diamonds, c 2 .clubs] == some 2
#guard fourOfAKind? #[c 2, c 2, c 2, c 1] == none
#guard fourOfAKind? #[c 2, c 2, c 2] == none
#guard fourOfAKind? #[] == none

-- AI gives away the rarest kind; ties keep every tied card as a candidate
#guard leastCommonIndices #[c 0, c 0, c 0, c 1] == #[3]
#guard leastCommonIndices #[c 0, c 0, c 1, c 2] == #[2, 3]
#guard leastCommonIndices #[c 0, c 0, c 1, c 1] == #[0, 1, 2, 3]
#guard leastCommonIndices #[c 0, c 1, c 2, c 3] == #[0, 1, 2, 3]

-- The exchanging pair walks clockwise around the table and wraps
#guard (List.range 5).map (exchangePair 4) == [(0, 1), (1, 2), (2, 3), (3, 0), (0, 1)]

-- A fresh deck dealt in order gives everyone four of a kind
#guard winners (dealFrom (deck 4) 4) == #[0, 1, 2, 3]

-- Exchanging swaps exactly the chosen cards
#guard
  let hands := #[#[c 0, c 0, c 0, c 1], #[c 0, c 1, c 1, c 1]]
  let after := exchange hands 0 1 3 0
  winners hands == #[] && winners after == #[0, 1]

-- The received card takes the slot of the card given away; the rest stay where they were
#guard
  let hands := #[#[c 3, c 0, c 1, c 2], #[c 1, c 2, c 0, c 3]]
  exchange hands 0 1 1 3 == #[#[c 3, c 3, c 1, c 2], #[c 1, c 2, c 0, c 0]]

end Tests

end FourCards
