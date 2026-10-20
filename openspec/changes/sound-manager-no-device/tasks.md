## 1. Implementation

- [ ] 1.1 `hxd.snd.Manager.new`: catch any exception from creating the driver and its sources, dispose the driver, go without one
- [ ] 1.2 `hxd.snd.Manager.driverError`

## 2. Verification

- [ ] 2.1 `tests/NoDeviceTest.hx`: with a driver that throws a `haxe.Exception`, `Manager.get()` returns a Manager with no driver and that error, and a channel plays virtually to its end
- [ ] 2.2 `haxe all.hxml` builds
