# four_cards

A command-line card game written in Lean 4. You play against AI opponents and try to be the
first to collect four cards of the same kind.

## Rules

- With `n` players the deck holds four cards of each of `n` kinds. Four players use the Aces,
  Kings, Queens and Jacks; more players add Tens, Nines and so on.
- The deck is shuffled and every player is dealt four cards.
- Exchanges go clockwise around the table: first player 1 and player 2 each pick one card from
  their hand and swap them, then player 2 and player 3, and so on, wrapping around from the
  last player to player 1. Both players pick before they see what they receive.
- A player who holds four cards of the same kind after an exchange shouts "4 cards!" and wins.
  If both players of the exchange complete their set at once, the game is a tie.
- A player who is dealt four of a kind wins straight away.

You sit in seat 1 and choose your card by typing its number. AI players give away a card of
the kind they hold the fewest of, choosing at random when several kinds are tied.

## Running

```
lake build
lake exe four_cards
```

Options:

| Option | Meaning |
| --- | --- |
| `-n`, `--players N` | number of players, 2 to 13 (default 4) |
| `-s`, `--seed N` | seed for the shuffle and the AI, for repeatable games |
| `-a`, `--auto` | no human player: watch the AI players play each other, all cards shown |
| `-m`, `--max-exchanges N` | call the game a draw after `N` exchanges (default 10000) |
| `-h`, `--help` | show the help text |

For example, `lake exe four_cards -n 6` starts a six-player game.

## Statistics

`lake exe simulate` plays many games without a human and prints win rates and game lengths
as Markdown tables. [STATISTICS.md](STATISTICS.md) holds the results of one such run and what
they show.

| Option | Meaning |
| --- | --- |
| `-g`, `--games N` | games per line-up (default 100000) |
| `-s`, `--seed N` | seed for the random generator (default 2026) |
| `-m`, `--max-exchanges N` | call a game unfinished after `N` exchanges (default 10000) |

## Layout

- `FourCards/Card.lean` - cards, ranks and the deck
- `FourCards/Game.lean` - dealing, exchanging and win detection
- `FourCards/Tactic.lean` - the ways a player can choose a card, including the AI's
- `FourCards/Simulation.lean` - playing whole games without the console and tallying them
- `Main.lean` - the game: command-line options, the prompt and the game loop
- `Simulate.lean` - the statistics runner

The library modules contain `#guard` checks that run at build time.
