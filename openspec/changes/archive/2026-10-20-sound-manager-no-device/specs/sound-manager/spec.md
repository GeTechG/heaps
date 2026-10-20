## ADDED Requirements

### Requirement: no audio device, virtual mode
When creating the sound driver or allocating its sources throws, whatever the thrown value, `hxd.snd.Manager.get()` SHALL return a Manager without a driver instead of propagating it: a driver that was created SHALL be disposed, every channel SHALL be virtual, and channels SHALL advance and end as they do with a driver. `Manager.driverError` SHALL hold the exception, `null` when the driver was created.

#### Scenario: Driver throws a haxe.Exception
- **WHEN** the driver constructor throws a `haxe.Exception` and `Manager.get()` is called
- **THEN** the Manager is created without a driver, `driverError` holds that exception, and a played channel is virtual and ends after its duration

#### Scenario: Device opens
- **WHEN** the driver is created
- **THEN** `driverError` is `null`
