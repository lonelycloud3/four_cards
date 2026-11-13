# Four Cards statistics

How often player 1 wins a four-player game under three combinations of tactics, and how the
length of the game grows from 4 to 8 players. The figures come from 100,000 simulated games
per line-up, except in the last section, which states its own source.

## Findings

- **Collecting Aces against random players:** player 1 wins 81.0% of the games.
- **Least occurring against random players:** player 1 wins 82.9%.
- **Collecting Aces against least-occurring players:** player 1 wins 11.5%, about half of
  what least occurring wins in the same seat.
- **Game length:** the average grows from 7.0 exchanges with 4 players to 31.0 with 8, a
  little faster than the square of the number of players.

## Setup

The rules are those in the [README](README.md). Three points matter for reading the numbers:

- Player 1 is the seat that takes part in the first exchange, with player 2.
- A player who is dealt four of a kind wins before any exchange. This decides 0.9% of
  four-player games, whatever the tactics.
- A win means holding four of a kind alone. Ties, where both players of an exchange complete
  their set at once, are counted separately.

The tactics:

| Tactic | Card given away |
| --- | --- |
| Random | Any of the four cards, with equal chance. |
| Least occurring | A card of the kind the player holds fewest of, with equal chance among tied cards. This is the game's AI. |
| Collects Aces | Any card that is not an Ace, with equal chance. Aces are never given away. |

## Player 1's win rate with four players

| Case | Player 1 | Other three players | P1 wins | P1 ties | P1 loses |
| --- | --- | --- | --- | --- | --- |
| 1 | Collects Aces | Random | 80.95% | 0.48% | 18.57% |
| 2 | Least occurring | Random | 82.91% | 0.52% | 16.57% |
| 3 | Collects Aces | Least occurring | 11.47% | 1.46% | 87.06% |

For comparison, player 1's results when all four players use the same tactic:

| Reference | All four players | P1 wins | P1 ties | P1 loses |
| --- | --- | --- | --- | --- |
| A | Random | 24.97% | 0.15% | 74.89% |
| B | Least occurring | 22.33% | 2.86% | 74.81% |

Every win rate is accurate to within 0.3 percentage points (95% confidence). No game reached
the limit of 10,000 exchanges.

**Cases 1 and 2.** Against random players, either tactic wins about four games out of five,
more than three times the 25.0% a random player gets in that seat (reference A). Least
occurring is ahead of collecting Aces by 2.0 percentage points, a small difference but well
outside the margin of error. It also wins faster: its games last 30 exchanges on average,
against 38 for collecting Aces and 231 when everybody plays randomly.

**Case 3.** Against least-occurring players, collecting Aces wins about half as often as
least occurring does in the same seat (11.5% against the 22.3% of reference B). Player 2
gains the most, as the table below shows.

### Wins per seat

Share of the games each seat wins alone. The rest of each row is ties.

| Line-up | Player 1 | Player 2 | Player 3 | Player 4 | Ties |
| --- | --- | --- | --- | --- | --- |
| Case 1 | 80.95% | 6.49% | 5.48% | 6.53% | 0.55% |
| Case 2 | 82.91% | 5.92% | 4.91% | 5.66% | 0.60% |
| Case 3 | 11.47% | 31.94% | 28.14% | 23.45% | 5.00% |
| Reference A | 24.97% | 25.01% | 24.94% | 24.76% | 0.32% |
| Reference B | 22.33% | 27.79% | 23.98% | 19.73% | 6.18% |

The seat matters when everybody plays least occurring (reference B): player 2 wins most often
and player 4 least. With random play the seats are equal.
[Why the seats differ](#why-the-seats-differ) explains this.

## Game length and the number of players

All players use least occurring. Games decided by the deal count as 0 exchanges.

| Players | Mean exchanges | Added by the extra player | Mean per player | Median | 90% of games end within | Longest game |
| --- | --- | --- | --- | --- | --- | --- |
| 4 | 6.97 | | 1.74 | 6 | 12 | 40 |
| 5 | 11.20 | +4.23 | 2.24 | 10 | 19 | 54 |
| 6 | 16.55 | +5.35 | 2.76 | 15 | 28 | 82 |
| 7 | 23.20 | +6.65 | 3.31 | 22 | 38 | 108 |
| 8 | 31.00 | +7.80 | 3.88 | 29 | 51 | 141 |

The means are accurate to within 0.09 exchanges (95% confidence). No game reached the limit
of 10,000 exchanges.

- **The growth accelerates.** Each extra player adds more exchanges than the one before:
  4.2, 5.4, 6.7, then 7.8.
- **Doubling the table multiplies the length by about 4.4.** From 4 to 8 players the mean
  goes from 6.97 to 31.00, which corresponds to growth with the power 2.15 of the number of
  players.
- **Each extra player costs about half a trip around the table.** "Mean per player" is the
  mean divided by the number of players, that is, how many times the exchange goes around
  the table. It rises by 0.50 to 0.57 per added player.
- **A quadratic fits the range.** With `n` players, `0.603 n² - 1.23 n + 2.25` reproduces
  all five means to within 0.03 exchanges. It is a fit to 4 to 8 players only and was not
  checked outside that range.

## Reproducing

```
lake exe simulate
```

This plays 100,000 games per line-up with seed 2026, the settings used here, and prints the
tables the figures above were taken from. It takes about half a minute. `--games`, `--seed` and
`--max-exchanges` change the settings.

The simulation uses the same dealing, exchanging and win detection as the game
(`FourCards/Game.lean`); the tactics are in `FourCards/Tactic.lean` and the tallying in
`FourCards/Simulation.lean`.

## Why the seats differ

When everybody plays least occurring, player 2 wins most often and player 4 least
([wins per seat](#wins-per-seat)). The cause is the order of the exchanges. The game is a
short race, and the seats differ in when their exchanges come and in whom they meet.

The figures in this section come from two separate runs, of 200,000 and of 60,000 games, made
with one-off scripts that are not part of `simulate`.

### Player 2 plays early in every lap, player 4 late

One lap around the table is four exchanges: P1–P2, P2–P3, P3–P4, P4–P1. Once the hands have
developed, any exchange may be the last one: in the second lap, between 17% and 23% of the
games still running end at each exchange. A later exchange therefore often never takes place.

| Exchange | Players | Games that get this far |
| --- | --- | --- |
| 5 | P1–P2 | 72% |
| 6 | P2–P3 | 60% |
| 7 | P3–P4 | 48% |
| 8 | P4–P1 | 38% |

Player 2 plays the first two exchanges of every lap, player 4 the last two.

### The player who has just played has the edge

In every exchange, one of the two players also took part in the exchange just before: player
2 in P2–P3, player 3 in P3–P4, player 4 in P4–P1 and player 1 in P1–P2. That player completes
its set more often than its partner, because it more often holds three of a kind already.

| Share of exchanges | Player who has just played | Its partner |
| --- | --- | --- |
| First lap: completes its set | 4.8% | 2.8% |
| First lap: holds three of a kind beforehand | 22.8% | 13.4% |
| Later laps: completes its set | 13.2% | 10.3% |
| Later laps: holds three of a kind beforehand | 47.5% | 39.7% |

In the first lap this is a head start. At exchange 2, player 2 has already improved its hand
once, while player 3 still holds the cards it was dealt: player 2 wins 5.3% of these
exchanges and player 3 wins 1.9%.

Player 1 is the only player without such a head start. In exchange 1 both players hold the
cards they were dealt (1.6% each), and in exchange 5 players 1 and 2 are still level (7.9%
and 8.0%).

Why the edge lasts beyond the first lap is only partly explained. One contributor is
confirmed: cards come back around. In half of the later exchanges, the player who has just
played passes on the very card it received one exchange earlier, so unwanted cards travel
clockwise with the exchanges. As a result the partner is more often handed a card it has
given away before (30% of exchanges against 22%). Such a card completes a set in only 2% to
3% of the cases, against 14% to 16% for a card the player has not given away before.

### Both effects per player

Every player has one exchange per lap right after its previous one and one exchange as the
partner. The table shows where in the lap they fall and how many games the player wins in
each.

| Player | Wins right after its previous exchange | Wins as the partner | Total |
| --- | --- | --- | --- |
| 2 | 16.0% (exchange 2 of the lap) | 11.6% (exchange 1) | 27.7% |
| 3 | 13.9% (exchange 3) | 9.7% (exchange 2) | 23.6% |
| 1 | 12.7% (exchange 1) | 9.5% (exchange 4) | 22.3% |
| 4 | 12.1% (exchange 4) | 7.5% (exchange 3) | 19.6% |

These are shares of all games. Games decided by the deal are left out, so the totals are
slightly below those in [wins per seat](#wins-per-seat).

Player 2 has its stronger exchange early in the lap. Player 4 has both of its exchanges
late.

### Random play has neither effect

With random play the seats are equal, which fits both explanations:

- Random hands do not improve with play, so nobody gets a head start.
- A random game lasts 231 exchanges on average, about 58 laps. Only about 0.4% of the games
  still running end at any one exchange, so playing earlier in a lap is worth almost nothing.
