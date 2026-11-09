## ADDED Requirements

### Requirement: a virtual channel advances at its pitch
A virtual channel SHALL advance its position by the elapsed time multiplied by its pitch rate: the value of the channel's own `Pitch` effect, else of its channel group's `Pitch` effect, else 1, and never below 0. Its end, loop and next queued sound SHALL follow that position.

#### Scenario: Pitch on the channel
- **WHEN** a virtual channel with a `Pitch(2)` effect runs for 0.5 s
- **THEN** its position advances by 1 s

#### Scenario: Pitch on the channel group
- **WHEN** a virtual channel without a `Pitch` effect, in a channel group with `Pitch(0.5)`, runs for 1 s
- **THEN** its position advances by 0.5 s

#### Scenario: Channel pitch over the group's
- **WHEN** a virtual channel has `Pitch(2)` and its channel group `Pitch(0.5)`, and it runs for 0.5 s
- **THEN** its position advances by 1 s

#### Scenario: End at pitch
- **WHEN** a virtual channel of a 1 s sound has `Pitch(2)`
- **THEN** it ends after 0.5 s

#### Scenario: No pitch
- **WHEN** a virtual channel and its group have no `Pitch` effect, and it runs for 0.5 s
- **THEN** its position advances by 0.5 s
