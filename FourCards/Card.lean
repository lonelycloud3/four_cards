/-!
# Cards and decks

A card is a rank plus a suit. Only the rank ("kind") matters for the rules of the game;
suits exist so that the four cards of one kind are distinguishable on screen.
-/

namespace FourCards

inductive Suit where
  | spades | hearts | diamonds | clubs
  deriving Repr, DecidableEq, Inhabited

namespace Suit

def all : Array Suit := #[spades, hearts, diamonds, clubs]

def name : Suit → String
  | spades => "Spades"
  | hearts => "Hearts"
  | diamonds => "Diamonds"
  | clubs => "Clubs"

def symbol : Suit → String
  | spades => "♠"
  | hearts => "♥"
  | diamonds => "♦"
  | clubs => "♣"

def toNat : Suit → Nat
  | spades => 0
  | hearts => 1
  | diamonds => 2
  | clubs => 3

end Suit

/-- Rank names, strongest first. A game with `n` players uses the first `n` of them. -/
def rankNames : Array String :=
  #["Ace", "King", "Queen", "Jack", "Ten", "Nine", "Eight", "Seven", "Six", "Five", "Four",
    "Three", "Two"]

/-- Every player needs a kind of their own, so the ranks limit the table size. -/
def maxPlayers : Nat := rankNames.size

/-- Number of cards in a hand, and of each kind in the deck. -/
def handSize : Nat := 4

def rankName (rank : Nat) : String :=
  rankNames.getD rank s!"Rank {rank}"

/-- Short labels shown on the cards, in the same order as `rankNames`: the first letter for
aces and face cards, the number for the rest. -/
def rankLabels : Array String :=
  #["A", "K", "Q", "J", "10", "9", "8", "7", "6", "5", "4", "3", "2"]

def rankLabel (rank : Nat) : String :=
  rankLabels.getD rank s!"#{rank}"

def rankPlural (rank : Nat) : String :=
  let name := rankName rank
  if name == "Six" then "Sixes" else name ++ "s"

structure Card where
  /-- Index into `rankNames`. -/
  rank : Nat
  suit : Suit
  deriving Repr, DecidableEq, Inhabited

namespace Card

/-- Long form, e.g. "King of Spades". -/
def name (c : Card) : String :=
  s!"{rankName c.rank} of {c.suit.name}"

/-- Short form used on screen, e.g. "K♠". -/
def label (c : Card) : String :=
  rankLabel c.rank ++ c.suit.symbol

instance : ToString Card := ⟨label⟩

/-- Display order: by rank, then by suit. -/
def lt (a b : Card) : Bool :=
  a.rank < b.rank || (a.rank == b.rank && a.suit.toNat < b.suit.toNat)

end Card

/-- The deck for `players` players: four cards of each of the first `players` kinds. -/
def deck (players : Nat) : Array Card := Id.run do
  let mut cards := #[]
  for rank in [0:players] do
    for suit in Suit.all do
      cards := cards.push { rank, suit }
  return cards

#guard (deck 4).size == 16
#guard (deck 4).all (·.rank < 4)
#guard maxPlayers == 13
#guard rankLabels.size == rankNames.size
#guard (deck 5).map Card.label ==
  #["A♠", "A♥", "A♦", "A♣", "K♠", "K♥", "K♦", "K♣", "Q♠", "Q♥", "Q♦", "Q♣",
    "J♠", "J♥", "J♦", "J♣", "10♠", "10♥", "10♦", "10♣"]

end FourCards
