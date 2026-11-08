## Context

`hxd/Window.js.hx` turns `touchend` into `ERelease` per changed touch (`onTouchEnd`). `touchcancel` has no listener.

## Goals / Non-Goals

**Goals:** a cancelled touch is released; the listener is removed by `dispose`.
**Non-Goals:** a distinct "cancelled" release in `hxd.Event`; touch handling on other targets.

## Decisions

- **Plain `ERelease`, via `onTouchEnd`.** `hxd.Event` has no cancellation mark for a release (`Event.cancel` is the interactive's "as if outside" switch, set by handlers, not by the window). `EReleaseOutside` was considered and rejected: `hxd.SceneEvents` clears its push list only on `ERelease`, so the pushed interactive would stay pushed, and `hxd.Key` drops every pressed key on it. `ERelease` gives the pushed interactive its release (a release outside when the touch left it) and clears the push list.
- `touchcancel` is registered and removed next to the other touch listeners, with the same method reference, so `dispose` keeps removing everything.

## Risks / Trade-offs

- A touch cancelled while over the interactive it pushed reads as a click. Accepted: it is what an ended touch at that point does, and Heaps has no other release to send.
