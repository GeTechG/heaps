## 1. Virtual clock at the pitch rate

- [ ] 1.1 `tests/VirtualPitchTest.hx`: interp test with a Manager without a driver covering the scenarios of `sound-manager` "a virtual channel advances at its pitch" (channel pitch, group pitch, channel over group, end at pitch, no pitch); fails before 1.2
- [ ] 1.2 `hxd/snd/Manager.hx`: `updateVirtualChannels` advances the position by the elapsed time times the pitch rate — checked by 1.1 passing
- [ ] 1.3 `tests/NoDeviceTest.hx` still passes; `haxe all.hxml`; AGENTS.md *Checks*

## Workflow follow-up

- Sprout bumps its heaps gitlink; TD-20 in Sprout's `docs/tech-debt.md` can be closed.
