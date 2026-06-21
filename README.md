# System Cleanup Utility

A professional Windows maintenance and cleanup utility built entirely with Batch Script (`.bat`).

System Cleanup Utility helps users safely free disk space by removing temporary files, caches, logs, and other non-essential system data while providing a modern console-based experience with real-time progress tracking, detailed logging, and cleanup reports.

---

## Features

### System Cleanup

* User Temp Files Cleanup
* Windows Temp Files Cleanup
* Prefetch Cleanup
* Recycle Bin Cleanup
* Recent Files History Cleanup

### Cache Cleanup

* DNS Cache Flush
* Thumbnail Cache Cleanup
* DirectX Shader Cache Cleanup
* Delivery Optimization Cache Cleanup
* Windows Error Reporting Cache Cleanup

### System Maintenance

* Windows Update Download Cache Cleanup
* Microsoft Store Cache Reset (WSReset)
* DISM Component Store Cleanup
* Silent Disk Cleanup Support

### Advanced Features

* Administrator Privilege Validation
* Real-Time Cleanup Progress
* Detailed Cleanup Logs
* Disk Space Analysis
* Space Recovery Calculation
* Cleanup Summary Report
* Optional Hibernation Removal
* Error Handling & Recovery
* Windows 10 Support
* Windows 11 Support

---

## Console Interface

The utility provides a professional terminal-based dashboard that displays:

* System Information
* Current Cleanup Section
* Active Cleanup Task
* Progress Indicators
* Success / Warning / Failure Status
* Disk Space Before Cleanup
* Disk Space After Cleanup
* Total Recovered Space
* Execution Time
* Cleanup Summary

Example:

```text
System Cleanup Utility

[SECTION 1/4] Temporary Files Cleanup

[✓] User Temp Files
[✓] Windows Temp Files
[✓] Prefetch Files

Progress:
[████████████████░░░░░░░░░░] 66%
```

---

## Safety

This utility is designed to remove only temporary and safe-to-delete system data.

The following items are never modified:

* Documents
* Downloads
* Pictures
* Videos
* Desktop Files
* Installed Applications
* Program Files
* Program Files (x86)
* Personal User Data
* Critical Windows System Files

---

## Logging

Every execution automatically generates a cleanup log.

Example:

```text
cleanup_20260622_143520.log
```

The log contains:

* Start Time
* End Time
* System Information
* Cleanup Tasks Executed
* Success / Failure Status
* Error Details
* Recovered Space Statistics

---

## Cleanup Report

At the end of execution, users can export a detailed cleanup report.

Example:

```text
cleanup_report.txt
```

The report includes:

* System Information
* Cleanup Summary
* Space Recovered
* Execution Time
* Success Count
* Failure Count

---

## Requirements

* Windows 10
* Windows 11
* Administrator Privileges

No additional software or dependencies required.

---

## Usage

1. Download the project.
2. Right-click `System_Cleanup.bat`.
3. Select **Run as Administrator**.
4. Follow the on-screen instructions.
5. Review the cleanup summary and generated log file.

---

## Project Structure

```text
System-Cleanup-Utility/
│
├── System_Cleanup.bat
├── Logs/
├── Reports/
└── README.md
```

---

## Why This Project?

Most cleanup scripts simply execute commands without providing any visibility into what is happening.

System Cleanup Utility focuses on:

* User Transparency
* Professional Console Experience
* Safe Cleanup Operations
* Detailed Reporting
* Reliable Error Handling

The goal is to provide a lightweight Windows maintenance utility that feels like a complete system optimization tool while remaining a single portable batch script.

---

## License

MIT License

Feel free to use, modify, and distribute this project.

---

## Author

Developed by Manorath Rastogi
