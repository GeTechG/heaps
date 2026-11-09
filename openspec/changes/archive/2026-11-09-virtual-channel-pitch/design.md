## Context

`Manager.updateVirtualChannels` advances a virtual channel by `now - lastStamp`. A real channel's position is synced from the samples its source played, which already reflects the pitch the driver applies. A real source receives the `Pitch` effects of the channel group and of the channel, applied in binding order — the group's first, the channel's last — so the channel's own value is the one the source plays at.

## Goals / Non-Goals

**Goals:** a virtual channel's clock runs at the rate a real source of the same channel would play.

**Non-Goals:** combining the channel and group pitch (the drivers do not multiply them); Doppler pitch from spatialization.

## Decisions

- Rate = the channel's `Pitch` value, else the channel group's, else 1; clamped at 0 so a negative value never rewinds. Multiplying the two was rejected: a real channel does not.
- Computed per update from `getEffect(Pitch)`, so adding, removing or changing the effect takes effect from the next update without extra state.

## Risks / Trade-offs

- A pitch changed between two updates applies to the whole interval, as a real source sees it only on the next `apply` as well.
