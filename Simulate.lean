import FourCards

/-!
# Statistics runner

Simulates many games and prints the tallies as Markdown tables:

1. the results of player 1 in four-player games, for several line-ups of tactics;
2. the length of the game for 4 to 8 players when everybody plays the AI tactic.
-/

open FourCards

structure Options where
  games : Nat := 100000
  seed : Nat := 2026
  maxExchanges : Nat := 10000
  help : Bool := false

def usage : String :=
  "Simulate Four Cards games and print statistics as Markdown tables.

Usage: simulate [OPTIONS]

Options:
  -g, --games N          games per line-up (default 100000)
  -s, --seed N           seed for the random generator (default 2026)
  -m, --max-exchanges N  call a game unfinished after N exchanges (default 10000)
  -h, --help             show this help"

def parseOptions : List String → Options → Except String Options
  | [], opts => pure opts
  | flag :: rest, opts =>
    let withValue (apply : Nat → Options) : Except String Options :=
      match rest with
      | value :: rest =>
        match value.toNat? with
        | some n => parseOptions rest (apply n)
        | none => throw s!"{flag} expects a whole number, got '{value}'"
      | [] => throw s!"{flag} expects a value"
    match flag with
    | "-h" | "--help" => pure { opts with help := true }
    | "-g" | "--games" => withValue fun n => { opts with games := n }
    | "-s" | "--seed" => withValue fun n => { opts with seed := n }
    | "-m" | "--max-exchanges" => withValue fun n => { opts with maxExchanges := n }
    | _ => throw s!"unknown option '{flag}'"

/-- A non-negative number with a fixed number of decimals. -/
def fixed (x : Float) (decimals : Nat) : String :=
  let scale := 10 ^ decimals
  let scaled := (x * scale.toFloat).round.toUInt64.toNat
  if decimals == 0 then
    toString scaled
  else
    let fraction := toString (scaled % scale)
    s!"{scaled / scale}.{"".pushn '0' (decimals - fraction.length)}{fraction}"

def percent (count total : Nat) : String :=
  fixed (100 * count.toFloat / total.toFloat) 2 ++ "%"

/-- Half-width of the 95% confidence interval of a share, in percentage points. -/
def margin (count total : Nat) : String :=
  let p := count.toFloat / total.toFloat
  fixed (100 * 1.96 * (p * (1 - p) / total.toFloat).sqrt) 2

/-- Number and share of the games that hit the exchange limit. -/
def unfinished (t : Tally) : String :=
  s!"{t.draws} ({percent t.draws t.games})"

def row (cells : List String) : String :=
  "| " ++ " | ".intercalate cells ++ " |"

structure LineUp where
  label : String
  first : String
  others : String
  tactics : Array Tactic

def ace : Nat := 0

/-- Player 1 plays `first`, the other three play `others`. -/
def lineUp (label first others : String) (firstTactic othersTactic : Tactic) : LineUp :=
  { label, first, others, tactics := #[firstTactic, othersTactic, othersTactic, othersTactic] }

def lineUps : List LineUp :=
  [ lineUp "1" "collects Aces" "random" (.keepRank ace) .random,
    lineUp "2" "least occurring" "random" .leastCommon .random,
    lineUp "3" "collects Aces" "least occurring" (.keepRank ace) .leastCommon,
    lineUp "A" "random" "random" .random .random,
    lineUp "B" "least occurring" "least occurring" .leastCommon .leastCommon ]

def run (opts : Options) : IO Unit := do
  IO.setRandSeed opts.seed
  let out ← IO.getStdout
  IO.println s!"games per line-up: {opts.games}, seed: {opts.seed}, \
    exchange limit: {opts.maxExchanges}\n"

  IO.println "## Player 1 in four-player games\n"
  IO.println (row ["Case", "Player 1", "Others", "P1 wins", "±", "P1 ties", "P1 loses",
    "Unfinished", "Mean exchanges", "Median", "90th percentile", "Longest"])
  IO.println (row (List.replicate 12 "---"))
  let mut seatRows := #[]
  for l in lineUps do
    let t ← simulate l.tactics opts.games opts.maxExchanges
    let wins := t.soleWins[0]!
    let ties := t.ties[0]!
    IO.println (row [l.label, l.first, l.others, percent wins t.games, margin wins t.games,
      percent ties t.games, percent (t.games - wins - ties - t.draws) t.games,
      unfinished t, fixed t.meanExchanges 2, toString (t.percentile 50),
      toString (t.percentile 90), toString t.longest])
    out.flush
    let seats := (List.range 4).map fun seat => percent t.soleWins[seat]! t.games
    seatRows := seatRows.push (row ([l.label] ++ seats ++ [percent t.tieGames t.games,
      percent t.dealtWins t.games]))

  IO.println "\n## Sole wins per seat\n"
  IO.println (row ["Case", "Player 1", "Player 2", "Player 3", "Player 4", "Ties",
    "Decided by the deal"])
  IO.println (row (List.replicate 7 "---"))
  for r in seatRows do
    IO.println r

  IO.println "\n## Game length when everybody plays least occurring\n"
  IO.println (row ["Players", "Mean exchanges", "±", "Exchanges per player", "Median",
    "90th percentile", "Longest", "Unfinished", "Ties"])
  IO.println (row (List.replicate 9 "---"))
  for n in [4:9] do
    let t ← simulate (Array.replicate n .leastCommon) opts.games opts.maxExchanges
    IO.println (row [toString n, fixed t.meanExchanges 2, fixed (1.96 * t.meanExchangesError) 2,
      fixed (t.meanExchanges / n.toFloat) 2, toString (t.percentile 50),
      toString (t.percentile 90), toString t.longest, unfinished t,
      percent t.tieGames t.games])
    out.flush

def main (args : List String) : IO UInt32 := do
  match parseOptions args {} with
  | .error message =>
    IO.eprintln s!"simulate: {message}"
    IO.eprintln "Try 'simulate --help'."
    return 2
  | .ok opts =>
    if opts.help then
      IO.println usage
    else if opts.games == 0 then
      IO.eprintln "simulate: --games must be at least 1"
      return 2
    else
      run opts
    return 0
