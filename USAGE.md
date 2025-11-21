# Cyber Apocalypse: Omega Protocol - Enhanced Edition

## Security Awareness Training Demonstration Tool

**Version:** 2.0 Enhanced Edition
**Purpose:** Educational tool for authorized security awareness training
**Platform:** Windows PowerShell 5.1+

---

## ⚠️ IMPORTANT DISCLAIMER

This tool is designed **EXCLUSIVELY** for:
- **Authorized internal security testing**
- **Security awareness training programs**
- **Educational demonstrations with explicit consent**

**This tool should NEVER be used:**
- Without proper authorization
- On systems you don't own or have permission to test
- To harass, frighten, or harm others
- In any malicious capacity

---

## 🚀 Quick Start

### Basic Usage (Full Hollywood Mode)
```powershell
.\prank.ps1
```

### With Consent Screen (Recommended for Training)
```powershell
.\prank.ps1 -ShowConsent -Mode Training -EducationalMode
```

### Demo Mode with Pause Capability
```powershell
.\prank.ps1 -Intensity Moderate -Mode Demo
```

---

## 📋 Configuration Options

### Intensity Levels

| Level | Description | Window Movement | Type Speed | Max Modules |
|-------|-------------|-----------------|------------|-------------|
| **Mild** | Subtle, fewer windows | Rare | Slow | 3 |
| **Moderate** | Noticeable activity | Moderate | Medium | 6 |
| **Hollywood** | Full chaos mode (default) | Aggressive | Fast | 12 |

### Modes

| Mode | Description | Features |
|------|-------------|----------|
| **FullAuto** | Continuous automatic progression | No pauses, full automation |
| **Demo** | Pausable demonstration | Press 'P' to pause/resume |
| **Training** | Educational mode | Shows debrief summary at end |

### Parameters

```powershell
-Intensity <Mild|Moderate|Hollywood>   # Visual intensity level
-Mode <Demo|Training|FullAuto>         # Execution mode
-ShowConsent                           # Display consent screen before starting
-EducationalMode                       # Show educational popups during execution
```

---

## 🎯 Usage Examples

### Example 1: Security Awareness Training Session
```powershell
# Full training experience with consent and educational notes
.\prank.ps1 -ShowConsent -Mode Training -EducationalMode -Intensity Hollywood
```

### Example 2: Instructor-Led Demo
```powershell
# Pausable demo for step-by-step explanation
.\prank.ps1 -Mode Demo -Intensity Moderate -EducationalMode
```

### Example 3: Mild Background Demo
```powershell
# Subtle demonstration for ongoing conference/event
.\prank.ps1 -Intensity Mild -Mode FullAuto
```

---

## 🛑 Emergency Stop Methods

**MULTIPLE ways to stop the demonstration:**

1. **Press ESC key** - Immediate shutdown
2. **Press Ctrl+C** - Terminate all processes
3. **Type "secret"** - Hidden killswitch (works in any window)

---

## 🎬 Attack Simulation Modules

The enhanced edition includes realistic simulations of:

### 1. **Initial Access & Reconnaissance**
- Exploits CVE-2023-23397 (Outlook vulnerability)
- Domain enumeration
- Network discovery

### 2. **Privilege Escalation**
- PrintNightmare (CVE-2021-34527) exploitation
- Elevation to SYSTEM privileges

### 3. **Credential Harvesting**
- Mimikatz-style credential dumping
- LSASS memory extraction simulation

### 4. **Lateral Movement**
- Pass-the-Hash attacks
- PSExec remote execution
- Network propagation visualization

### 5. **Persistence**
- Registry run keys
- Scheduled tasks
- WMI event subscriptions
- Golden ticket creation

### 6. **Data Exfiltration**
- C2 communication channels
- DNS tunneling
- Sensitive data staging

### 7. **Ransomware Deployment**
- File encryption simulation
- Ransom note display
- Countdown timers

### 8. **Total Compromise**
- Maximum chaos mode
- All modules active

---

## 📚 Educational Features

When `-EducationalMode` is enabled, the script displays:

- **Training Notes** during each attack phase
- **Real CVE references** for vulnerabilities
- **Defense recommendations** for each technique
- **Incident response guidance**

### Debrief Screen (Training Mode)

After the demonstration, Training mode shows a comprehensive debrief including:
- Multi-stage attack kill chain explanation
- Defense strategies
- Incident response best practices
- Reporting procedures

---

## 🎨 Visual Effects

The enhanced edition includes:

- **ASCII Art Banners** for major attack phases
- **Realistic Progress Bars** with intermediate steps
- **Color-Coded Alerts** (Red=Critical, Yellow=Warning, etc.)
- **Coordinated Window Choreography**
- **Multiple Terminal Styles** (Matrix, Hex dumps, Network maps, etc.)

---

## 🔊 Audio Effects

Enhanced sound effects for:
- Breach alerts
- Encryption sounds
- Access granted/denied
- Data transmission
- Critical warnings
- Countdown beeps

*Note: Audio respects Intensity setting (Mild = no sounds)*

---

## 🎪 Demo Mode Controls

When running in Demo mode:

- **Press 'P'** - Pause/Resume the demonstration
- Allows instructor to explain each phase
- Perfect for live training sessions

---

## 💻 Technical Requirements

- **OS:** Windows 10/11 or Windows Server 2016+
- **PowerShell:** Version 5.1 or later
- **Execution Policy:** Must allow script execution
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
  ```
- **Administrator Rights:** Not required (runs in user context)

---

## 🔧 Troubleshooting

### Script won't run
```powershell
# Set execution policy for current session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Then run the script
.\prank.ps1
```

### Encoding errors with special characters
The enhanced edition uses ASCII-safe characters to avoid encoding issues. If you still see errors, ensure you're using PowerShell 5.1 or later.

### Windows don't spawn
- Check if Windows Defender or antivirus is blocking CMD/PowerShell
- Ensure you have permission to spawn new processes
- Try running from a local path (not network drive)

---

## 📖 Best Practices for Training Sessions

1. **Always get explicit consent** from participants
2. **Use ShowConsent flag** to display warning screen
3. **Brief participants** on the killswitch methods before starting
4. **Use Demo mode** for instructor-led sessions
5. **Enable EducationalMode** for maximum learning value
6. **Debrief afterwards** - discuss what was observed and how to defend
7. **Document the training** - log who attended and what was covered

---

## 🎓 Learning Outcomes

Participants in this training demonstration will learn:

- How multi-stage cyber attacks unfold
- Real-world attack techniques and tools
- The cyber kill chain methodology
- Importance of defense-in-depth
- How to recognize suspicious activity
- When and how to report security incidents

---

## 📝 Changelog - Enhanced Edition

### New Features
- ✨ Multiple intensity levels (Mild, Moderate, Hollywood)
- ✨ Three execution modes (Demo, Training, FullAuto)
- ✨ Educational popups with real security information
- ✨ Debrief summary screen
- ✨ Consent screen option
- ✨ Pausable Demo mode
- ✨ Enhanced killswitch options (ESC, Ctrl+C, "secret")

### New Attack Modules
- 🆕 Ransomware simulation
- 🆕 Keylogger demonstration
- 🆕 Lateral movement visualization
- 🆕 Data exfiltration module

### Improvements
- 🎨 ASCII art banners
- 🎨 Better color schemes and visual hierarchy
- 🔊 Expanded sound effects library
- 📊 Realistic progress bars with intermediate steps
- 🎯 Real CVE references (CVE-2023-23397, CVE-2021-34527, MS14-068)
- ⚡ Better performance and smoother animations
- 🐛 Fixed encoding issues with Unicode characters
- 🎬 Coordinated window choreography
- 📚 Enhanced educational content

---

## 📞 Support

For questions about using this tool for security awareness training:
- Review the code to understand what it does
- Test in an isolated environment first
- Consult your IT security team before deployment

---

## ⚖️ License & Legal

This tool is provided for **AUTHORIZED EDUCATIONAL PURPOSES ONLY**.

By using this tool, you agree to:
- Only use it with proper authorization
- Only use it for legitimate security training
- Not use it for harassment or malicious purposes
- Comply with all applicable laws and regulations

The authors are not responsible for misuse of this tool.

---

## 🙏 Acknowledgments

Created for security awareness training to help organizations educate their staff about cyber threats and the importance of security best practices.

**Remember: Security is everyone's responsibility!** 🔒
