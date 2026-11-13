import FourCards.Tactic

/-!
# Simulation

Plays complete games without any console interaction and tallies the results. The game loop
uses the same dealing, exchanging and win detection as the interactive game.
-/

namespace FourCards

structure Outcome where
  /-- Seats holding four of a kind at the end. Empty when the exchange limit was reached. -/
  winners : Array Nat
  /-- Number of exchanges played. Zero when somebody was dealt four of a kind. -/
  exchanges : Nat

/-- Play one game. Seat `i` plays `tactics[i]`; the number of players is `tactics.size`. -/
def simulateGame (tactics : Array Tactic) (maxExchanges : Nat) : IO Outcome := do
  let n := tactics.size
  let mut hands ← deal n
  let mut won := winners hands
  let mut played := 0
  for turn in [0:maxExchanges] do
    unless won.isEmpty do
      break
    let (a, b) := exchangePair n turn
    let i ← tactics[a]!.choose hands[a]!
    let j ← tactics[b]!.choose hands[b]!
    hands := exchange hands a b i j
    won := winners hands
    played := turn + 1
  return { winners := won, exchanges := played }

/-- Results of many games with the same line-up. -/
structure Tally where
  games : Nat := 0
  /-- Per seat: games won alone. -/
  soleWins : Array Nat
  /-- Per seat: games ending in a tie that includes the seat. -/
  ties : Array Nat
  /-- Games ending in a tie. -/
  tieGames : Nat := 0
  /-- Games stopped by the exchange limit. -/
  draws : Nat := 0
  /-- Games decided by the deal, before any exchange. -/
  dealtWins : Nat := 0
  /-- Total exchanges over the finished games. -/
  exchangeSum : Nat := 0
  exchangeSquareSum : Nat := 0
  /-- Longest finished game. -/
  longest : Nat := 0
  /-- `histogram[k]` is the number of finished games that lasted `k` exchanges. -/
  histogram : Array Nat

namespace Tally

def empty (players maxExchanges : Nat) : Tally :=
  { soleWins := Array.replicate players 0
    ties := Array.replicate players 0
    histogram := Array.replicate (maxExchanges + 1) 0 }

def record (t : Tally) (o : Outcome) : Tally :=
  let t := { t with games := t.games + 1 }
  if o.winners.isEmpty then
    { t with draws := t.draws + 1 }
  else
    let t :=
      { t with
        exchangeSum := t.exchangeSum + o.exchanges
        exchangeSquareSum := t.exchangeSquareSum + o.exchanges * o.exchanges
        longest := max t.longest o.exchanges
        histogram := t.histogram.modify o.exchanges (· + 1)
        dealtWins := if o.exchanges == 0 then t.dealtWins + 1 else t.dealtWins }
    match o.winners.toList with
    | [seat] => { t with soleWins := t.soleWins.modify seat (· + 1) }
    | seats =>
      { t with
        tieGames := t.tieGames + 1
        ties := seats.foldl (fun acc seat => acc.modify seat (· + 1)) t.ties }

/-- Games that ended with somebody holding four of a kind. -/
def finished (t : Tally) : Nat :=
  t.games - t.draws

/-- Mean number of exchanges in a finished game. -/
def meanExchanges (t : Tally) : Float :=
  t.exchangeSum.toFloat / t.finished.toFloat

/-- Standard error of `meanExchanges`. -/
def meanExchangesError (t : Tally) : Float :=
  let n := t.finished.toFloat
  let mean := t.meanExchanges
  let variance := t.exchangeSquareSum.toFloat / n - mean * mean
  (variance / n).sqrt

/-- The smallest `k` such that at least `percent`% of the finished games lasted `k`
exchanges or fewer. -/
def percentile (t : Tally) (percent : Nat) : Nat := Id.run do
  let target := (t.finished * percent + 99) / 100
  let mut seen := 0
  for k in [0:t.histogram.size] do
    seen := seen + t.histogram[k]!
    if seen ≥ target then
      return k
  return t.histogram.size - 1

end Tally

/-- Play `games` games with the given line-up. -/
def simulate (tactics : Array Tactic) (games maxExchanges : Nat) : IO Tally := do
  let mut tally := Tally.empty tactics.size maxExchanges
  for _ in [0:games] do
    tally := tally.record (← simulateGame tactics maxExchanges)
  return tally

end FourCards
