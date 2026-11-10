# vrm-fan-control

Quiet, temperature-driven control of the VRM fans and CPU cooler on the **ASUS ROG Zenith Extreme Alpha (X399)** under Linux.

## Why

- On this board the two small VRM heatsink fans are a known problem: on their own header (HS_FAN) they run at ~6,000–8,000 RPM and ignore Q-Fan settings.
- Moving them to **CPU_FAN** makes them controllable, but CPU_FAN shares one control channel with CPU_OPT (the CPU cooler), the BIOS won't go below ~20 % in DC mode, and its curve can only follow the CPU's Tctl, which on a Threadripper 1920X reads 27 °C high.
- The board's Super I/O chip is an **ITE IT8665E**. The mainline kernel has no driver for it, but [frankcrawford/it87](https://github.com/frankcrawford/it87) does. Its `pwm1` drives CPU_FAN + CPU_OPT.

## What it does

`vrm-fan-control` sets `pwm1` every 2 s from whichever of these needs more cooling:

| Source | Ramp |
|---|---|
| CPU VRM temperature (`asus_wmi_sensors`) | idle until 60 °C → 100 % at 85 °C |
| real CPU temperature, Tdie (`k10temp`) | idle until 55 °C → 100 % at 80 °C |

- It rises immediately and falls slowly, so the fans don't flap.
- The idle floor `IDLE_PWM=40` gives ~1,500–1,900 RPM on the VRM fans, which is quiet.
- **If the service stops or crashes, control goes back to the BIOS curve** (`pwm1_enable=2`).

Settings live in `/etc/default/vrm-fan-control`. After editing, run `systemctl restart vrm-fan-control`.

## Install

```sh
sudo ./install.sh
```

## Caveats

- `it87` must load with `ignore_resource_conflict=1`, because ASUS ACPI/WMI also uses the Super I/O. Some owners of this board saw fans get stuck when software accessed the chip at the same time as the firmware. If that happens, `systemctl stop vrm-fan-control` hands control back to the BIOS.
- The DKMS module is unsigned, so keep Secure Boot off (BIOS → Boot → Secure Boot → OS Type: Other OS).
