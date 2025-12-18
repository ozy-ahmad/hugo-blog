
---
title: "Fixing Xbox Series X|S Controller with official Dongle on Arch Linux (Omarchy)"
date: 2025-12-18
publish: true
draft: false
tags: ["linux", "games"]
categories: ["blog"]
summary: "Using Xbox controller with official USB dongle required runtime firmware and user-space darmon called xow."

---
![xboxcontroller](/images/xboxcontroller.png)

Using an **Xbox Wireless Controller (Series X|S, USB‑C)** with the **official Microsoft USB dongle** on Linux is not plug‑and‑play.

Unlike Bluetooth, the dongle requires runtime firmware and a user‑space daemon called `xow`.

This note documents the **minimal, working setup** that finally made it work.



## Environment

- OS: Arch Linux (Omarchy)
- Kernel: 6.x
- Controller: Xbox Wireless Controller (Series X|S, USB‑C, Carbon Black)
- Dongle: Microsoft Xbox Wireless Adapter (`045e:02fe`)
- Desktop: Hyprland
- Games: Steam




## Controller Details

- Official product page:  
	[https://www.xbox.com/en-US/accessories/controllers/xbox-wireless-controller-usb-c](https://www.xbox.com/en-US/accessories/controllers/xbox-wireless-controller-usb-c)

- Connection modes:
    
    - USB‑C (wired)
        
    - Xbox Wireless (2.4 GHz via official dongle)
        



## The Problem

Symptoms I hit:

- Controller LED keeps blinking
    
- Dongle visible in `lsusb` but will not pair
    
- `xow` service crashes or restarts
    
- Errors like:
    
    - `Failed to load firmware`
        
    - `Firmware reset timed out`
        
    - `LIBUSB_ERROR_ACCESS`
        

Sometimes the service looked _active_, but nothing actually worked.



## Why This Happens

`xow` is **not a kernel driver**.

It:

- Runs in user space
- Talks to the dongle via `libusb`
- Uploads Microsoft firmware at runtime
- Emulates an Xbox controller for Linux input devices

If firmware is missing or pairing order is wrong, the dongle stays unusable.



## The Fix

### 1. Install xow

```bash
git clone https://github.com/medusalix/xow.git
cd xow
make
sudo make install
```



### 2. Install firmware (required)

```bash
sed "s|@prefix@|/usr/local|g" install/firmware.sh.in > /tmp/xow-firmware.sh
chmod +x /tmp/xow-firmware.sh
sudo /tmp/xow-firmware.sh
```

This installs:

```
/lib/firmware/xow_dongle.bin
```

Verify:

```bash
ls -l /lib/firmware/xow_dongle.bin
```



### 3. systemd Service Configuration

This is the working `xow` service file I ended up using.

```ini
[Unit]
Description=Xbox One Wireless Dongle Driver

[Service]
Type=simple
ExecStart=/usr/local/bin/xow
Restart=on-failure
Environment="XOW_COMPATIBILITY=1"

[Install]
WantedBy=multi-user.target
```

Edit it with:

```bash
sudo SYSTEMD_EDITOR=nvim systemctl edit --full xow
```

Enable and start:

```bash
sudo systemctl enable xow --now
```



### 4. Pair Using USB (Important)

For Xbox Series X|S controllers, pairing **once via USB** is required.

Steps:

1. Plug controller using a USB‑C cable
    
2. Start `xow`
    
3. Wait for:
    
    ```
    Dongle initialized
    ```
    
4. Unplug the USB cable
    
5. Press pairing button on:
    
    - Dongle
        
    - Controller
        

After this, wireless pairing works normally.



## Verify

- `journalctl -u xow` shows:
    
    - `Dongle initialized`
        
    - `Pairing enabled`
        
- Controller LED becomes solid
    
- Steam detects an **Xbox Controller**
    
- Games receive input
    



## Lessons Learned

- The official Xbox dongle requires firmware (xow or xone)
- `xow` is a user‑space USB translator, not a kernel driver
- USB pairing once is necessary for Series X|S controllers
- Linux exposes complexity that Windows hides


## TL;DR

```
Install xow
Install firmware
Enable service
Pair once via USB
Use wireless after
```


## References

- xow: [https://github.com/medusalix/xow](https://github.com/medusalix/xow)
- Xbox Controller: [https://www.xbox.com/en-US/accessories/controllers/xbox-wireless-controller-usb-c](https://www.xbox.com/en-US/accessories/controllers/xbox-wireless-controller-usb-c)