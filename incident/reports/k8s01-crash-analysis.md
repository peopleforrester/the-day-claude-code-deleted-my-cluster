# k8s01 Crash Analysis Report

## Summary
k8s01 (192.168.0.50) is experiencing hardware interrupt issues causing system instability and requiring power cycles.

## Key Findings

### 1. IRQ 16 Storm
- **Issue**: Kernel is disabling IRQ 16 due to interrupt storm
- **Error**: `kernel: Disabling IRQ #16`
- **Devices on IRQ 16**:
  - idma64.0 (DMA controller)
  - i2c_designware.0 (I2C controller)
  - i801_smbus (SMBus controller)
  - snd_hda_intel:card1 (Audio device)

### 2. Recent Reboot History
```
Jul 30 13:54 - Current boot (up 3.5 hours)
Jul 30 13:49 - Previous boot (4 minutes uptime)
Jul 29 01:48 - Boot before that (1 day 12 hours)
Jul 25 09:23 - 5 days uptime
```

### 3. System Resources
- **Memory**: 15GB total, 12GB free (no memory pressure)
- **Disk**: 468GB total, 12GB used (3% utilization)
- **CPU**: Low usage, no overheating (sensors not installed)

### 4. Secondary Issues
- MetalLB speaker pod crash looping on k8s01
- Network connectivity timeouts after IRQ disabled
- ACPI BIOS errors (non-critical)

## Root Cause Analysis

The primary issue is an **IRQ 16 interrupt storm** likely caused by:
1. Faulty hardware device (possibly SMBus or audio controller)
2. Driver bug or incompatibility
3. BIOS/firmware issue

When the kernel disables IRQ 16, it affects multiple devices sharing that interrupt, leading to system instability.

## Recommended Actions

### Immediate Workarounds
1. **Disable audio if not needed**:
   ```bash
   echo "blacklist snd_hda_intel" > /etc/modprobe.d/blacklist-audio.conf
   update-initramfs -u
   ```

2. **Try IRQ polling mode**:
   Add to GRUB kernel parameters:
   ```
   irqpoll
   ```

3. **Disable specific problematic device**:
   Check which device is causing issues:
   ```bash
   watch -n 1 'cat /proc/interrupts | grep "16:"'
   ```

### Long-term Solutions
1. **Update BIOS/firmware** to latest version
2. **Update kernel** to 6.15.x or newer
3. **Replace hardware** if specific component identified as faulty
4. **Move workloads** off k8s01 until stable

### Monitoring
Set up monitoring for:
- IRQ counts: `/proc/interrupts`
- Kernel messages: `dmesg | grep -i irq`
- System uptime and reboot frequency

## Conclusion
k8s01 has a hardware/driver issue causing IRQ storms. This is not a Kubernetes issue but a system-level problem requiring hardware troubleshooting or driver updates.
