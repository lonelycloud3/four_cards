import FourCards

open FourCards

structure Config where
  players : Nat := 4
  /-- Seed for the random generator; `none` lets the system pick one. -/
  seed : Option Nat := none
  /-- No human player: every seat is played by the AI and all cards are shown. -/
  auto : Bool := false
  /-- The game is declared a draw after this many exchanges. -/
  maxExchanges : Nat := 10000
  help : Bool := false

def usage : String :=
  s!"Four Cards - collect four cards of the same kind before anyone else does.

Usage: four_cards [OPTIONS]

Options:
  -n, --players N        number of players, 2 to {maxPlayers} (default 4)
  -s, --seed N           seed for the shuffle and the AI, for repeatable games
  -a, --auto             no human player: watch the AI players play each other
  -m, --max-exchanges N  call the game a draw after N exchanges (default 10000)
  -h, --help             show this help"

def parseNat (flag value : String) : Except String Nat :=
  match value.toNat? with
  | some n => pure n
  | none => throw s!"{flag} expects a whole number, got '{value}'"

def parseArgs : List String → Config → Except String Config
  | [], cfg => pure cfg
  | flag :: rest, cfg =>
    let withValue (apply : Nat → Config) : Except String Config :=
      match rest with
      | value :: rest => do parseArgs rest (apply (← parseNat flag value))
      | [] => throw s!"{flag} expects a value"
    match flag with
    | "-h" | "--help" => pure { cfg with help := true }
    | "-a" | "--auto" => parseArgs rest { cfg with auto := true }
    | "-n" | "--players" => withValue fun n => { cfg with players := n }
    | "-s" | "--seed" => withValue fun n => { cfg with seed := some n }
    | "-m" | "--max-exchanges" => withValue fun n => { cfg with maxExchanges := n }
    | _ => throw s!"unknown option '{flag}'"

def validate (cfg : Config) : Except String Config :=
  if cfg.help then
    pure cfg
  else if cfg.players < 2 || cfg.players > maxPlayers then
    throw s!"the number of players must be between 2 and {maxPlayers}, got {cfg.players}"
  else
    pure cfg

/-- The human, when there is one, always sits in the first seat. -/
def Config.isHuman (cfg : Config) (player : Nat) : Bool :=
  !cfg.auto && player == 0

def Config.name (cfg : Config) (player : Nat) : String :=
  if cfg.isHuman player then "You" else s!"Player {player + 1}"

def showHand (hand : Hand) : String :=
  " ".intercalate (hand.toList.map toString)

def printHands (cfg : Config) (hands : Array Hand) : IO Unit := do
  let width := hands.size.fold (fun i _ acc => max acc (cfg.name i).length) 0
  for i in [0:hands.size] do
    let name := cfg.name i
    let padding := "".pushn ' ' (width - name.length)
    IO.println s!"  {name}:{padding} {showHand hands[i]!}"

/-- Ask the human which card to give away. Returns a position in `hand`. -/
partial def promptCard (hand : Hand) (partner : String) : IO Nat := do
  IO.print s!"Which card do you give to {partner}? [1-{hand.size}, q to quit]: "
  (← IO.getStdout).flush
  let line ← (← IO.getStdin).getLine
  if line.isEmpty then
    -- End of input (Ctrl+Z / Ctrl+D or a closed pipe).
    IO.println "\nNo more input - goodbye!"
    IO.Process.exit 0
  let input := line.trimAscii.toString.toLower
  if input == "q" || input == "quit" || input == "exit" then
    IO.println "Goodbye!"
    IO.Process.exit 0
  match input.toNat? with
  | some k =>
    if 1 ≤ k && k ≤ hand.size then
      return k - 1
    IO.println s!"There is no card number {k}."
  | none =>
    unless input.isEmpty do
      IO.println s!"'{input}' is not a card number."
  promptCard hand partner

/-- The position of the card `player` gives to `partner`. -/
def chooseCard (cfg : Config) (hands : Array Hand) (player partner : Nat) : IO Nat := do
  let hand := hands[player]!
  if cfg.isHuman player then
    let numbered := (List.range hand.size).map fun i => s!"[{i + 1}] {hand[i]!}"
    IO.println s!"Your hand:  {"   ".intercalate numbered}"
    promptCard hand (cfg.name partner)
  else
    Tactic.leastCommon.choose hand

/-- Let everyone holding four of a kind shout. Returns `true` if the game is over. -/
def announceWinners (cfg : Config) (hands : Array Hand) : IO Bool := do
  let won := winners hands
  if won.isEmpty then
    return false
  IO.println ""
  for player in won do
    let verb := if cfg.isHuman player then "shout" else "shouts"
    IO.println s!"{cfg.name player} {verb}: \"4 cards!\""
  IO.println ""
  match won.toList with
  | [player] =>
    let kind := rankPlural ((fourOfAKind? hands[player]!).getD 0)
    let verb := if cfg.isHuman player then "win" else "wins"
    IO.println s!"{cfg.name player} {verb} with four {kind}!"
  | players =>
    let names := players.map fun p => if cfg.isHuman p then "you" else cfg.name p
    let last := names.getLast!
    let others := ", ".intercalate names.dropLast
    IO.println s!"It's a tie between {others} and {last}!"
  IO.println "\nFinal hands:"
  printHands cfg hands
  return true

/-- Tell the audience what happened in an exchange, without leaking hidden cards. -/
def reportExchange (cfg : Config) (a b : Nat) (cardA cardB : Card) : IO Unit := do
  if cfg.auto then
    IO.println s!"  {cfg.name a} gives {cardA}, {cfg.name b} gives {cardB}."
  else if cfg.isHuman a then
    IO.println s!"You give {cardA} to {cfg.name b} and receive {cardB}."
  else if cfg.isHuman b then
    IO.println s!"You give {cardB} to {cfg.name a} and receive {cardA}."
  else
    IO.println s!"  {cfg.name a} and {cfg.name b} exchange a card."

def play (cfg : Config) : IO Unit := do
  if let some seed := cfg.seed then
    IO.setRandSeed seed
  let n := cfg.players
  IO.println s!"Four Cards - {n} players, {n * handSize} cards in the deck."
  IO.println "Players take turns exchanging one card with their clockwise neighbour."
  IO.println "The first to hold four cards of the same kind wins."
  let mut hands ← deal n
  if cfg.auto then
    IO.println "\nStarting hands:"
    printHands cfg hands
  -- Somebody may be dealt a complete set straight away.
  if ← announceWinners cfg hands then
    return
  for turn in [0:cfg.maxExchanges] do
    let (a, b) := exchangePair n turn
    IO.println s!"\nExchange {turn + 1}: {cfg.name a} <-> {cfg.name b}"
    -- Both players choose before seeing what they receive.
    let i ← chooseCard cfg hands a b
    let j ← chooseCard cfg hands b a
    let cardA := hands[a]![i]!
    let cardB := hands[b]![j]!
    hands := exchange hands a b i j
    reportExchange cfg a b cardA cardB
    if cfg.auto then
      printHands cfg hands
    if ← announceWinners cfg hands then
      return
  IO.println s!"\nNobody collected four of a kind in {cfg.maxExchanges} exchanges - it's a draw."
  IO.println "\nFinal hands:"
  printHands cfg hands

def main (args : List String) : IO UInt32 := do
  match parseArgs args {} >>= validate with
  | .error message =>
    IO.eprintln s!"four_cards: {message}"
    IO.eprintln "Try 'four_cards --help'."
    return 2
  | .ok cfg =>
    if cfg.help then
      IO.println usage
    else
      play cfg
    return 0
