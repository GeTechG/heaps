## 1. Implementation

- [x] 1.1 `hxd.snd.Manager.new`: catch any exception from creating the driver and its sources, dispose the driver, go without one
- [x] 1.2 `hxd.snd.Manager.driverError`
- [x] 1.3 an empty source list without a driver, so `timeOffset` works in virtual mode

## 2. Verification

- [x] 2.1 `tests/NoDeviceTest.hx`: with a driver that throws a `haxe.Exception`, `Manager.get()` returns a Manager with no driver and that error, and a channel plays virtually to its end
- [x] 2.2 `haxe all.hxml` builds
