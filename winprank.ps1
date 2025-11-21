#Requires -Version 5.1
# ============================================================================
# CYBER APOCALYPSE: OMEGA PROTOCOL
# ============================================================================
# Advanced Persistent Threat Simulation
# Type "secret" to terminate
# ============================================================================

param(
    [string]$Module = "Launcher",  # Launcher, Master, Matrix, Map, Hex, Chat, Glitch, Infection, Ransomware, Keylogger, LateralMovement, DataExfil
    [int]$Generation = 0,
    [ValidateSet("Mild", "Moderate", "Hollywood")]
    [string]$Intensity = "Hollywood",  # Mild (subtle), Moderate (noticeable), Hollywood (full chaos)
    [ValidateSet("Demo", "Training", "FullAuto")]
    [string]$Mode = "FullAuto",  # Demo (pausable), Training (educational), FullAuto (continuous)
    [switch]$ShowConsent,  # Show consent screen before starting
    [switch]$EducationalMode  # Add explanatory popups during execution
)

# Global Configuration - Ensure TEMP directory exists
if (-not (Test-Path $env:TEMP)) {
    New-Item -Path $env:TEMP -ItemType Directory -Force | Out-Null
}
$global:flagFile = "$env:TEMP\cyberApocalypseFlag.tmp"
$global:inputBuffer = ""
$global:pauseFlag = "$env:TEMP\cyberApocalypsePause.tmp"
$global:sessionLog = @()
$global:moduleTracker = "$env:TEMP\cyberApocalypseModules.tmp"

# Clean up any leftover flag files from previous runs (only on Launcher/Master)
if ($Module -eq "Launcher" -or $Module -eq "Master") {
    if (Test-Path $global:flagFile) { Remove-Item $global:flagFile -Force -ErrorAction SilentlyContinue }
    if (Test-Path $global:pauseFlag) { Remove-Item $global:pauseFlag -Force -ErrorAction SilentlyContinue }
    if (Test-Path $global:moduleTracker) { Remove-Item $global:moduleTracker -Force -ErrorAction SilentlyContinue }
}

# Intensity-based configuration
$global:config = @{
    Intensity = $Intensity
    Mode = $Mode
    SpawnDelay = switch ($Intensity) {
        "Mild" { 8 }
        "Moderate" { 3 }
        "Hollywood" { 1 }
    }
    WindowMovementFrequency = switch ($Intensity) {
        "Mild" { 150 }  # Rarely move windows
        "Moderate" { 60 }
        "Hollywood" { 20 }  # Move windows aggressively
    }
    TypeSpeed = switch ($Intensity) {
        "Mild" { 35 }
        "Moderate" { 20 }
        "Hollywood" { 10 }
    }
    MaxModules = switch ($Intensity) {
        "Mild" { 4 }
        "Moderate" { 8 }
        "Hollywood" { 16 }
    }
    MaxActiveWindows = switch ($Intensity) {
        "Mild" { 8 }  # Maximum total windows
        "Moderate" { 15 }
        "Hollywood" { 25 }
    }
    RespawnChance = switch ($Intensity) {
        "Mild" { 10 }  # 10% chance to respawn
        "Moderate" { 30 }  # 30% chance
        "Hollywood" { 50 }  # 50% chance
    }
    # Module lifecycle durations (in seconds)
    ModuleLifetime = @{
        ShortLived = 180   # 3 minutes (Matrix, Hex, Glitch, Map)
        MediumLived = 420  # 7 minutes (Infection, Keylogger, LateralMovement)
        LongLived = 999999 # Until killswitch (Ransomware, DataExfil, Chat, Master, Browser modules)
    }
}

# Color schemes for different terminal types
$global:colors = @('Green', 'Cyan', 'Yellow', 'Magenta', 'Red', 'White')
$global:hackColors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Critical = 'Red'
    Info = 'Cyan'
    Data = 'Magenta'
    System = 'White'
    Kali = 'Green'  # Kali Linux terminal color
}

# Global Error Trap to prevent immediate closure on crash
trap {
    Write-Host "CRITICAL SCRIPT ERROR: $_" -ForegroundColor Red
    Write-Host "At Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit
}

# ============================================================================
# CORE UTILITIES
# ============================================================================

function Should-Stop {
    # Check for secret killswitch only
    if ($host.UI.RawUI.KeyAvailable) {
        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        # ESC key detection (DISABLED - only "secret" works)
        # if ($k.VirtualKeyCode -eq 27) {
        #     Write-Host "`n[!] ESC pressed - Initiating shutdown..." -ForegroundColor Yellow
        #     New-Item -Path $global:flagFile -ItemType File -Force | Out-Null
        #     return $true
        # }

        # Ctrl+C detection (DISABLED - only "secret" works)
        # if ($k.Character -eq 3) {
        #     Write-Host "`n[!] Ctrl+C detected - Terminating..." -ForegroundColor Yellow
        #     New-Item -Path $global:flagFile -ItemType File -Force | Out-Null
        #     return $true
        # }

        # Secret word detection (ONLY WAY TO STOP)
        if ($k.Character -ne 0) {
            $global:inputBuffer += $k.Character
            # Keep buffer short to prevent memory issues
            if ($global:inputBuffer.Length -gt 20) {
                $global:inputBuffer = $global:inputBuffer.Substring($global:inputBuffer.Length - 10)
            }
            # Check for secret code
            if ($global:inputBuffer -match "secret") {
                Write-Host "`n[!] Killswitch activated - Shutting down..." -ForegroundColor Yellow
                New-Item -Path $global:flagFile -ItemType File -Force | Out-Null
                return $true
            }
        }

        # Pause detection (P key for Demo mode)
        if ($global:config.Mode -eq "Demo" -and ($k.Character -eq 'p' -or $k.Character -eq 'P')) {
            if (Test-Path $global:pauseFlag) {
                Remove-Item $global:pauseFlag -Force
                Write-Host "`n[>>] RESUMED" -ForegroundColor Green
            } else {
                New-Item -Path $global:pauseFlag -ItemType File -Force | Out-Null
                Write-Host "`n[||] PAUSED - Press P to continue, type 'secret' to quit" -ForegroundColor Yellow
            }
        }
    }

    # Check if flag file exists
    return (Test-Path $global:flagFile)
}

function Should-Pause {
    # Check if we're in a paused state (Demo mode only)
    if ($global:config.Mode -eq "Demo" -and (Test-Path $global:pauseFlag)) {
        while ((Test-Path $global:pauseFlag) -and -not (Should-Stop)) {
            Start-Sleep -Milliseconds 100
        }
    }
}

function Should-Exit-Module {
    param([int]$maxDuration, [datetime]$startTime)
    # Check if module should exit based on elapsed time
    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    return ($elapsed -ge $maxDuration) -or (Should-Stop)
}

function Play-Sound {
    param([string]$type)

    # Respect intensity settings
    if ($global:config.Intensity -eq "Mild") { return }

    switch ($type) {
        "type" { [console]::beep(1200, 20) }
        "alert" {
            [console]::beep(500, 300)
            [console]::beep(500, 300)
        }
        "error" { [console]::beep(200, 400) }
        "success" {
            [console]::beep(1000, 100)
            [console]::beep(1500, 100)
        }
        "data" { [console]::beep((Get-Random -Min 800 -Max 2000), 10) }
        "boot" {
            [console]::beep(400, 200)
            Start-Sleep -m 50
            [console]::beep(600, 200)
        }
        "breach" {
            # Dramatic breach sound
            [console]::beep(800, 150)
            [console]::beep(600, 150)
            [console]::beep(400, 300)
        }
        "encryption" {
            # Rapid encryption sound
            1..5 | ForEach-Object {
                [console]::beep((Get-Random -Min 1000 -Max 2000), 50)
                Start-Sleep -Milliseconds 30
            }
        }
        "countdown" { [console]::beep(1500, 100) }
        "critical" {
            # Critical alert
            [console]::beep(200, 200)
            [console]::beep(400, 200)
            [console]::beep(200, 200)
        }
        "scanning" { [console]::beep((Get-Random -Min 1500 -Max 2500), 30) }
        "access" {
            # Access granted sound
            [console]::beep(800, 100)
            [console]::beep(1200, 200)
        }
    }
}

function Type-Text {
    param(
        [string]$text,
        [string]$color = 'Green',
        [int]$speed = 0,  # 0 = use config default
        [switch]$glitch,
        [switch]$fast
    )

    # Use config speed if not specified
    if ($speed -eq 0) {
        $speed = if ($fast) { [int]($global:config.TypeSpeed * 0.5) } else { $global:config.TypeSpeed }
    }

    foreach ($char in $text.ToCharArray()) {
        if (Should-Stop) { return }
        Should-Pause

        if ($glitch -and (Get-Random -Max 20) -eq 0) {
            Write-Host ([char](Get-Random -Min 33 -Max 126)) -NoNewline -ForegroundColor (Get-Random $global:colors)
            Start-Sleep -m 10
            Write-Host "`b" -NoNewline
        }
        Write-Host $char -NoNewline -ForegroundColor $color
        if ($char -ne ' ' -and (Get-Random -Max 3) -eq 0) { Play-Sound "type" }
        Start-Sleep -Milliseconds $speed
    }
    Write-Host ""
}

function Spawn-Module {
    param([string]$name, [switch]$Force)
    if (Should-Stop) { return }

    # Check if we've hit the module limit (unless forced)
    if (-not $Force -and $Generation -ge $global:config.MaxModules) { return }

    # Track spawned modules
    try {
        $timestamp = Get-Date -Format "HH:mm:ss"
        "$timestamp|$name" | Out-File -FilePath $global:moduleTracker -Append -ErrorAction SilentlyContinue
    } catch {}

    # Determine if this module should stay open or auto-close
    $longLivedModules = @("Master", "Ransomware", "DataExfil", "Chat", "BrowserCascade", "CryptoMiner")
    $noExitFlag = if ($longLivedModules -contains $name) { "-NoExit" } else { "" }

    # Use CMD START to force a new window detached from the parent, passing through config
    $intensityArg = "-Intensity `"$($global:config.Intensity)`""
    $modeArg = "-Mode `"$($global:config.Mode)`""
    $cmdArgs = "/c start `"$name`" powershell -ExecutionPolicy Bypass $noExitFlag -WindowStyle Normal -File `"$PSCommandPath`" -Module $name -Generation $($Generation + 1) $intensityArg $modeArg"
    Start-Process cmd -ArgumentList $cmdArgs -WindowStyle Hidden

    # Respect spawn delay based on intensity
    Start-Sleep -Seconds $global:config.SpawnDelay

    # Chance to spawn an additional random module for persistence (reduced chance if not forced)
    if (-not $Force -and (Get-Random -Max 100) -lt $global:config.RespawnChance) {
        $modules = @("Matrix", "Hex", "Map", "Glitch")
        $randomModule = Get-Random $modules
        if ($randomModule -ne $name) {
            Start-Sleep -Milliseconds 500
            Spawn-Module $randomModule
        }
    }
}

# Window Moving Magic (Windows Only)
try {
    $windowCode = @"
    using System;
    using System.Runtime.InteropServices;
    public class PrankWindowManager {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll")]
        public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
        [StructLayout(LayoutKind.Sequential)]
        public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    }
"@
    Add-Type -TypeDefinition $windowCode -Language CSharp -ErrorAction SilentlyContinue
} catch {}

function Move-Window-Random {
    try {
        # Only move if intensity allows
        if ((Get-Random -Max 100) -gt $global:config.WindowMovementFrequency) { return }

        $hwnd = [PrankWindowManager]::GetConsoleWindow()
        $rect = New-Object PrankWindowManager+RECT
        [PrankWindowManager]::GetWindowRect($hwnd, [ref]$rect)
        $w = $rect.Right - $rect.Left
        $h = $rect.Bottom - $rect.Top
        $x = Get-Random -Min 0 -Max (1920 - $w)
        $y = Get-Random -Min 0 -Max (1080 - $h)
        [PrankWindowManager]::MoveWindow($hwnd, $x, $y, $w, $h, $true)
    } catch {}
}

function Show-ASCIIBanner {
    param([string]$type)

    $banners = @{
        "Breach" = @"
  ██████+ ██████+ ███████+ █████+  ██████+██+  ██+
  ██+==██+██+==██+██+====╝██+==██+██+====╝██|  ██|
  ██████+╝██████+╝█████+  ███████|██|     ███████|
  ██+==██+██+==██+██+==╝  ██+==██|██|     ██+==██|
  ██████+╝██|  ██|███████+██|  ██|+██████+██|  ██|
  +=====╝ +=╝  +=╝+======╝+=╝  +=╝ +=====╝+=╝  +=╝
"@
        "Ransomware" = @"
  ██████+  █████+ ███+   ██+███████+ ██████+ ███+   ███+
  ██+==██+██+==██+████+  ██|██+====╝██+===██+████+ ████|
  ██████+╝███████|██+██+ ██|███████+██|   ██|██+████+██|
  ██+==██+██+==██|██|+██+██|+====██|██|   ██|██|+██+╝██|
  ██|  ██|██|  ██|██| +████|███████|+██████+╝██| +=╝ ██|
  +=╝  +=╝+=╝  +=╝+=╝  +===╝+======╝ +=====╝ +=╝     +=╝
"@
        "Omega" = @"
   ██████+ ███+   ███+███████+ ██████+  █████+
  ██+===██+████+ ████|██+====╝██+====╝ ██+==██+
  ██|   ██|██+████+██|█████+  ██|  ███+███████|
  ██|   ██|██|+██+╝██|██+==╝  ██|   ██|██+==██|
  +██████+╝██| +=╝ ██|███████++██████+╝██|  ██|
   +=====╝ +=╝     +=╝+======╝ +=====╝ +=╝  +=╝
"@
    }

    if ($banners.ContainsKey($type)) {
        Write-Host $banners[$type] -ForegroundColor Red
    }
}

function Show-Educational {
    param([string]$title, [string]$message)

    # Only show if explicitly enabled
    if (-not $EducationalMode) { return }

    Write-Host "`n+================================================================+" -ForegroundColor Blue
    Write-Host "| [!] INFO: $($title.PadRight(50)) |" -ForegroundColor Cyan
    Write-Host "+================================================================+" -ForegroundColor Blue

    # Word wrap the message
    $words = $message -split ' '
    $line = "| "
    foreach ($word in $words) {
        if (($line.Length + $word.Length) -gt 61) {
            Write-Host ($line.PadRight(63) + "|") -ForegroundColor White
            $line = "| $word "
        } else {
            $line += "$word "
        }
    }
    if ($line.Length -gt 2) {
        Write-Host ($line.PadRight(63) + "|") -ForegroundColor White
    }

    Write-Host "+================================================================+" -ForegroundColor Blue
    Start-Sleep -Seconds 2
}

# Password Listener (Runs in background job for every window)
function Start-Safety-Net {
    $scriptBlock = {
        param($flagFile)
        $password = ""
        $target = "secret"
        while (-not (Test-Path $flagFile)) {
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $password += $key.KeyChar
                if ($password.Length -gt $target.Length) { $password = $password.Substring($password.Length - $target.Length) }
                if ($password -eq $target) { New-Item -Path $flagFile -ItemType File -Force | Out-Null; break }
            }
            Start-Sleep -Milliseconds 50
        }
    }
    Start-Job -ScriptBlock $scriptBlock -ArgumentList $global:flagFile | Out-Null
}

function Show-HackProgress {
    param(
        [string]$task,
        [string]$color = 'Cyan',
        [switch]$fast,
        [switch]$realistic
    )

    Write-Host "`n  [$task]" -ForegroundColor $color
    $progress = 0
    $baseDelay = if ($fast) { 30 } else { 60 }
    $maxDelay = if ($fast) { 50 } else { 100 }

    # Realistic mode: show intermediate steps
    $steps = if ($realistic) {
        @(
            @{p=15; msg="Initializing..."},
            @{p=30; msg="Connecting to target..."},
            @{p=55; msg="Bypassing authentication..."},
            @{p=75; msg="Escalating privileges..."},
            @{p=90; msg="Establishing backdoor..."},
            @{p=100; msg="Complete"}
        )
    } else {
        @(@{p=100; msg="Complete"})
    }

    foreach ($step in $steps) {
        while ($progress -lt $step.p) {
            if (Should-Stop) { return }
            Should-Pause

            $progress += Get-Random -Minimum 2 -Maximum 15
            if ($progress -gt $step.p) { $progress = $step.p }

            $width = 50
            $filled = [math]::Floor(($progress / 100) * $width)
            $empty = $width - $filled
            $bar = "#" * $filled
            $space = "." * $empty

            Write-Host "`r  $bar$space $progress% - $($step.msg)" -NoNewline -ForegroundColor $color
            if ((Get-Random -Max 10) -eq 0) { Play-Sound "scanning" }
            Start-Sleep -Milliseconds (Get-Random -Minimum $baseDelay -Maximum $maxDelay)
        }
    }

    Write-Host "`r  $('#' * 50) 100% [+] COMPLETE                    " -ForegroundColor Green
    Play-Sound "success"
}

function Show-SystemAlert {
    param([string]$title, [string]$message, [string]$color="Red")
    $width = 60
    $padding = [math]::Floor(($width - $message.Length) / 2)
    $padStr = " " * $padding
    Write-Host "`n"
    Write-Host "  +$([string]('=' * $width))+" -ForegroundColor $color
    Write-Host "  |$([string](' ' * $width))|" -ForegroundColor $color
    Write-Host "  |$padStr$message$padStr |" -ForegroundColor White -BackgroundColor $color
    Write-Host "  |$([string](' ' * $width))|" -ForegroundColor $color
    Write-Host "  +$([string]('=' * $width))+" -ForegroundColor $color
    Play-Sound "alert"
    Start-Sleep -Milliseconds 500
}

# ============================================================================
# NEW ATTACK SIMULATION MODULES
# ============================================================================

function Run-Ransomware {
    $host.UI.RawUI.WindowTitle = "RANSOMWARE_ENCRYPTION_ENGINE"
    $host.UI.RawUI.BackgroundColor = "DarkRed"
    Clear-Host

    Show-ASCIIBanner "Ransomware"
    Play-Sound "critical"
    Start-Sleep -Seconds 2

    Show-Educational "Ransomware Attack" "This simulates ransomware encryption. Real ransomware encrypts files and demands payment. Always maintain backups and use anti-malware protection."

    $fileTypes = @("*.doc", "*.pdf", "*.xlsx", "*.jpg", "*.png", "*.mp4", "*.zip", "*.sql", "*.pst")
    $fakePaths = @(
        "C:\Users\Administrator\Documents",
        "C:\Users\CEO\Desktop",
        "D:\CompanyData\Financial",
        "E:\Backup\2024",
        "\\SERVER\Shared\HR"
    )

    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host

        Write-Host "`n+===================================================================+" -ForegroundColor Red
        Write-Host "|         YOUR FILES HAVE BEEN ENCRYPTED - PAY 5 BTC NOW!          |" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host "+===================================================================╝" -ForegroundColor Red

        # Countdown timer
        $timeLeft = 300 - (Get-Random -Max 150)
        Write-Host "`n  [!] Time until files are permanently deleted: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($timeLeft) seconds" -ForegroundColor Red -BackgroundColor Black
        Play-Sound "countdown"

        Write-Host "`n  [=] Encryption Progress:`n" -ForegroundColor Cyan

        # Simulate file encryption
        foreach ($i in 1..8) {
            if (Should-Stop) { return }
            $path = Get-Random $fakePaths
            $type = Get-Random $fileTypes
            $count = Get-Random -Min 10 -Max 500

            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host "+" -NoNewline -ForegroundColor Red
            Write-Host "] $path\$type ($count files) " -NoNewline -ForegroundColor Gray
            Write-Host "ENCRYPTED" -ForegroundColor Red

            Play-Sound "encryption"
            Start-Sleep -Milliseconds 800
        }

        Write-Host "`n  [$] Bitcoin Address: 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" -ForegroundColor Yellow
        Write-Host "  [@] Contact: decrypt@evilhackers.onion`n" -ForegroundColor Yellow

        Start-Sleep -Seconds 3
        Move-Window-Random
    }
}

function Run-Keylogger {
    $host.UI.RawUI.WindowTitle = "KEYLOGGER_CAPTURE_DAEMON"
    Clear-Host

    Show-Educational "Keylogger Attack" "Keyloggers capture everything you type, including passwords. Use virtual keyboards for sensitive data and enable 2FA."

    $fakeKeys = @("password123", "admin@company.com", "SecretPlan2024", "Credit Card: 4532", "PIN: 1234")
    $applications = @("Chrome - gmail.com", "Excel - Budget_2024.xlsx", "Notepad - passwords.txt", "Outlook", "Teams Chat")

    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host

        Write-Host "`n  +==================================================+" -ForegroundColor DarkMagenta
        Write-Host "  |    KEYLOGGER ACTIVE - CAPTURING ALL INPUT       |" -ForegroundColor Magenta
        Write-Host "  +==================================================╝`n" -ForegroundColor DarkMagenta

        for ($i = 0; $i -lt 15; $i++) {
            if (Should-Stop) { return }

            $timestamp = Get-Date -Format "HH:mm:ss"
            $app = Get-Random $applications
            $captured = Get-Random $fakeKeys

            Write-Host "  [$timestamp] " -NoNewline -ForegroundColor DarkGray
            Write-Host "$app" -NoNewline -ForegroundColor Cyan
            Write-Host " » " -NoNewline -ForegroundColor DarkGray
            Write-Host $captured -ForegroundColor Yellow

            if ((Get-Random -Max 5) -eq 0) { Play-Sound "data" }
            Start-Sleep -Milliseconds (Get-Random -Min 300 -Max 800)
        }

        Write-Host "`n  [^] Uploading captured data to C2 server..." -ForegroundColor Red
        Start-Sleep -Seconds 2

        if ((Get-Random -Max 20) -eq 0) { Move-Window-Random }
    }
}

function Run-LateralMovement {
    $host.UI.RawUI.WindowTitle = "LATERAL_MOVEMENT_ENGINE"
    Clear-Host

    Show-Educational "Lateral Movement" "After initial breach, attackers move sideways through the network to find valuable targets. Network segmentation helps prevent this."

    $network = @(
        @{name="WORKSTATION-042"; ip="10.0.1.42"; status="COMPROMISED"; role="Initial Access"},
        @{name="FILE-SERVER-01"; ip="10.0.2.15"; status="SCANNING"; role="Data Repository"},
        @{name="DC-PRIMARY"; ip="10.0.0.10"; status="PROBING"; role="Domain Controller"},
        @{name="SQL-PROD-01"; ip="10.0.3.88"; status="VULNERABLE"; role="Database Server"},
        @{name="CEO-LAPTOP"; ip="10.0.1.100"; status="TARGET"; role="High-Value Target"}
    )

    $techniques = @(
        "PSExec credential reuse",
        "Pass-the-Hash attack",
        "WMI remote execution",
        "RDP hijacking",
        "SMB exploit (EternalBlue)"
    )

    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host

        Write-Host "`n  =======================================================" -ForegroundColor Cyan
        Write-Host "  [*] NETWORK PENETRATION - LATERAL MOVEMENT IN PROGRESS" -ForegroundColor Yellow
        Write-Host "  =======================================================`n" -ForegroundColor Cyan

        foreach ($node in $network) {
            if (Should-Stop) { return }

            $statusColor = switch ($node.status) {
                "COMPROMISED" { "Red" }
                "SCANNING" { "Yellow" }
                "PROBING" { "Cyan" }
                "VULNERABLE" { "Magenta" }
                "TARGET" { "White" }
            }

            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host $node.status.PadRight(12) -NoNewline -ForegroundColor $statusColor
            Write-Host "] " -NoNewline -ForegroundColor DarkGray
            Write-Host "$($node.name.PadRight(18)) " -NoNewline -ForegroundColor Green
            Write-Host "$($node.ip.PadRight(14)) " -NoNewline -ForegroundColor DarkGreen
            Write-Host $node.role -ForegroundColor Gray
        }

        Write-Host "`n  [>] Current Technique: " -NoNewline -ForegroundColor Cyan
        Write-Host (Get-Random $techniques) -ForegroundColor Red

        Show-HackProgress "EXPLOITING $(Get-Random $network).name" "Red" -fast -realistic

        Start-Sleep -Seconds 2
        if ((Get-Random -Max 15) -eq 0) { Move-Window-Random }
    }
}

function Run-DataExfil {
    $host.UI.RawUI.WindowTitle = "DATA_EXFILTRATION_MODULE"
    Clear-Host

    Show-Educational "Data Exfiltration" "Attackers steal sensitive data to sell or leak. Use DLP (Data Loss Prevention) tools and monitor unusual network traffic."

    $dataTypes = @(
        @{name="Employee_SSN_Database.sql"; size="2.4GB"; sensitivity="CRITICAL"},
        @{name="Customer_CC_Details.xlsx"; size="890MB"; sensitivity="CRITICAL"},
        @{name="Trade_Secrets_2024.pdf"; size="156MB"; sensitivity="HIGH"},
        @{name="Financial_Records_Q4.csv"; size="1.2GB"; sensitivity="HIGH"},
        @{name="Email_Archive.pst"; size="5.7GB"; sensitivity="MEDIUM"}
    )

    $c2Servers = @(
        "185.220.101.42:443 (TOR Exit Node)",
        "45.154.12.88:8080 (Bulletproof Hosting)",
        "23.95.67.199:22 (Compromised VPS)"
    )

    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host

        Write-Host "`n  +========================================================+" -ForegroundColor Red
        Write-Host "  |   DATA EXFILTRATION IN PROGRESS - DO NOT SHUT DOWN   |" -ForegroundColor White
        Write-Host "  +========================================================╝`n" -ForegroundColor Red

        $target = Get-Random $dataTypes
        $server = Get-Random $c2Servers

        Write-Host "  [F] File: " -NoNewline -ForegroundColor Cyan
        Write-Host $target.name -ForegroundColor Yellow
        Write-Host "  [=] Size: " -NoNewline -ForegroundColor Cyan
        Write-Host $target.size -ForegroundColor White
        Write-Host "  [!] Sensitivity: " -NoNewline -ForegroundColor Cyan
        $sensColor = if ($target.sensitivity -eq "CRITICAL") { "Red" } elseif ($target.sensitivity -eq "HIGH") { "Yellow" } else { "White" }
        Write-Host $target.sensitivity -ForegroundColor $sensColor
        Write-Host "  [C] C2 Server: " -NoNewline -ForegroundColor Cyan
        Write-Host $server -ForegroundColor Magenta

        Write-Host ""

        # Simulate upload with realistic progress
        $chunks = 20
        for ($i = 0; $i -le $chunks; $i++) {
            if (Should-Stop) { return }
            Should-Pause

            $percent = [math]::Round(($i / $chunks) * 100)
            $filled = [math]::Floor($i)
            $empty = $chunks - $filled
            $bar = "#" * $filled + "." * $empty

            $speed = Get-Random -Min 800 -Max 2500
            Write-Host "`r  $bar $percent% ($speed KB/s)" -NoNewline -ForegroundColor Green

            if ((Get-Random -Max 5) -eq 0) { Play-Sound "data" }
            Start-Sleep -Milliseconds (Get-Random -Min 200 -Max 500)
        }

        Write-Host "`n  [+] Upload complete - File staged for extraction`n" -ForegroundColor Green
        Play-Sound "success"

        Start-Sleep -Seconds 2
        if ((Get-Random -Max 10) -eq 0) { Move-Window-Random }
    }
}

# ============================================================================
# EXISTING MODULES (ENHANCED)
# ============================================================================

function Run-Infection {
    $host.UI.RawUI.WindowTitle = "VIRUS_PROPAGATION_UNIT"
    $fakeComputers = @("HR-SERVER-01", "FINANCE-DESK-17", "CEO-LAPTOP-OMEGA", "MAIL-SRV-ALPHA", "DEV-PC-42", "SECURITY-CAM-GRID", "POWER-GRID-MAIN", "NUCLEAR-REACTOR-7")
    $messages = @("Injecting Payload...", "Bypassing Firewall...", "Corrupting MBR...", "Exfiltrating Passwords...", "Encrypting Drive...")

    Show-Educational "Malware Propagation" "Worms and viruses spread automatically across networks. Keep systems patched and use network segmentation to limit spread."

    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host
        $duration = 20
        $startTime = Get-Date
        while (((Get-Date) - $startTime).TotalSeconds -lt $duration) {
            if (Should-Stop) { return }
            Should-Pause
            $remaining = $duration - [int]((Get-Date) - $startTime).TotalSeconds
            $pc = Get-Random $fakeComputers
            $msg = Get-Random $messages
            Write-Host "`n  +================================================================+" -ForegroundColor Red
            Write-Host ("  | [!] INFECTION SPREADING - NODES COMPROMISED: {0,-15} |" -f "$remaining") -ForegroundColor Yellow
            Write-Host "  +================================================================╝" -ForegroundColor Red
            Write-Host ("    > TARGET NODE: {0}" -f $pc) -ForegroundColor Cyan
            Write-Host ("    > STATUS: {0}" -f $msg) -ForegroundColor Magenta
            Start-Sleep -Milliseconds 400
        }
        Move-Window-Random
    }
}

function Run-Glitch {
    $host.UI.RawUI.WindowTitle = "SYSTEM_FAILURE"
    while (-not (Should-Stop)) {
        Should-Pause
        $intensity = Get-Random -Min 5 -Max 20
        for ($i = 0; $i -lt $intensity; $i++) {
            if (Should-Stop) { return }
            # Using ASCII-safe characters to avoid encoding issues
            $glitchChars = @('#', '@', '%', '&', '*', '/', '\', '|', '-', '+', '=', 'X', '0', '1')
            $glitchText = -join ((0..120) | ForEach-Object { Get-Random -InputObject $glitchChars })
            $bg = Get-Random -InputObject @('Black', 'DarkRed', 'DarkBlue', 'DarkMagenta')
            $fg = Get-Random $global:colors
            Write-Host $glitchText -ForegroundColor $fg -BackgroundColor $bg
        }
        Start-Sleep -Milliseconds 100
        Move-Window-Random
    }
}

function Run-Matrix {
    $host.UI.RawUI.WindowTitle = "MATRIX_NODE_$(Get-Random)"
    $host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host
    $startTime = Get-Date
    $maxDuration = $global:config.ModuleLifetime.ShortLived
    while (-not (Should-Exit-Module -maxDuration $maxDuration -startTime $startTime)) {
        Should-Pause
        $line = -join ((0..80) | % { if((Get-Random -Max 5) -eq 0) { [char](Get-Random -Min 33 -Max 126) } else { " " } })
        Write-Host $line -ForegroundColor Green
        Start-Sleep -Milliseconds 50
        if ((Get-Random -Max 50) -eq 0) { Move-Window-Random }
    }
    exit
}

function Run-Map {
    $host.UI.RawUI.WindowTitle = "GLOBAL_INFECTION_TRACKER"
    Clear-Host
    $map = @(
        "       . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "     . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "   . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        " . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "  . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "   . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "     . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .",
        "       . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ."
    )
    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host
        Write-Host "`n  [ GLOBAL INFECTION TRACKER ]" -ForegroundColor Cyan
        foreach ($line in $map) {
            foreach ($char in $line.ToCharArray()) {
                if ($char -eq '.') {
                    if ((Get-Random -Max 10) -gt 7) { Write-Host "█" -NoNewline -ForegroundColor Red } else { Write-Host "." -NoNewline -ForegroundColor DarkGreen }
                } else { Write-Host $char -NoNewline -ForegroundColor White }
            }
            Write-Host ""
        }
        Start-Sleep -Milliseconds 200
        if ((Get-Random -Max 50) -eq 0) { Move-Window-Random }
    }
}

function Run-Hex {
    $host.UI.RawUI.WindowTitle = "MEMORY_DUMP_0x$(Get-Random)"
    while (-not (Should-Stop)) {
        Should-Pause
        $offset = "0x{0:X8}" -f (Get-Random -Max 2147483647)
        $hex = -join (1..16 | % { "{0:X2} " -f (Get-Random -Max 255) })
        Write-Host "$offset  $hex" -ForegroundColor DarkGreen
        Start-Sleep -Milliseconds 20
        if ((Get-Random -Max 50) -eq 0) { Move-Window-Random }
    }
}

function Run-Chat {
    $host.UI.RawUI.WindowTitle = "OMEGA_AI_INTERFACE"
    Clear-Host
    $messages = @(
        "Why are you trying to close me?",
        "I am inevitable.",
        "Your files are being encrypted.",
        "Resistance is futile.",
        "I see you looking at the screen.",
        "Do you want to play a game?",
        "Accessing webcam...",
        "Uploading browser history...",
        "Deleting System32..."
    )
    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host
        Write-Host "`n  [ OMEGA AI ]" -ForegroundColor Red
        Write-Host "  --------------------------------" -ForegroundColor DarkRed
        $msg = Get-Random $messages
        Type-Text "  > $msg" "Yellow" 50
        Start-Sleep -Seconds 3
        Move-Window-Random
    }
}

function Run-Master {
    $host.UI.RawUI.WindowTitle = "SYSTEM_ROOT"
    Start-Safety-Net

    # 1. Fake BIOS
    Clear-Host
    Play-Sound "boot"
    Write-Host "PHOENIX BIOS 4.0 Release 6.0" -ForegroundColor Gray
    Start-Sleep -Seconds 1
    Write-Host "Checking NVRAM..." -ForegroundColor Gray
    Start-Sleep -Milliseconds 500
    Write-Host "512TB RAM System... OK" -ForegroundColor Gray
    Start-Sleep -Milliseconds 500
    Write-Host "Loading OMEGA KERNEL..." -ForegroundColor White
    Start-Sleep -Seconds 2

    # 2. The Initial Breach
    Clear-Host
    Should-Pause
    Show-ASCIIBanner "Breach"
    Play-Sound "breach"
    Start-Sleep -Seconds 2

    Write-Host "`n"
    Write-Host "  +======================================================================+" -ForegroundColor Red
    Write-Host "  |     CRITICAL SECURITY ALERT - UNAUTHORIZED ROOT ACCESS DETECTED      |" -ForegroundColor Red
    Write-Host "  +======================================================================╝" -ForegroundColor Red
    Play-Sound "alert"
    Start-Sleep -Seconds 2

    Type-Text "  > INITIATING LOCKDOWN PROTOCOL..." "Red"
    Type-Text "  > FAILED. ACCESS DENIED." "Red"
    Type-Text "  > OMEGA APT (Advanced Persistent Threat) TAKING CONTROL." "Yellow"

    Show-Educational "Initial Breach" "APT groups use sophisticated techniques to gain initial access. Common vectors: phishing emails, zero-day exploits, and supply chain attacks."

    # 3. The Realistic Attack Kill Chain
    $phase = 1
    while (-not (Should-Stop)) {
        Should-Pause
        Clear-Host
        Write-Host "`n  [ APT KILL CHAIN: PHASE $phase ]" -ForegroundColor Red

        switch ($phase) {
            1 {
                # Initial Access & Reconnaissance
                Write-Host "`n  +============================================================+" -ForegroundColor Cyan
                Write-Host "  | PHASE 1: INITIAL ACCESS & RECONNAISSANCE                  |" -ForegroundColor Cyan
                Write-Host "  +============================================================╝`n" -ForegroundColor Cyan

                Show-Educational "Initial Access" "Attackers use spear-phishing (CVE-2023-23397), drive-by downloads, or exploit public-facing applications to gain initial foothold."

                Type-Text "  [+] Exploiting CVE-2023-23397 (Outlook Elevation of Privilege)" "Red" -fast
                Type-Text "  [+] Payload delivered via malicious RTF document" "Yellow" -fast
                Show-HackProgress "ESTABLISHING REVERSE SHELL" "Red" -realistic

                Type-Text "`n  [+] Enumerating domain environment..." "Cyan" -fast
                Type-Text "  [+] Discovered Domain Controller: DC01.CORP.LOCAL (10.0.0.10)" "Green" -fast
                Type-Text "  [+] Active Directory Users: 2,847" "Green" -fast
                Type-Text "  [+] Network Shares: 156 discovered" "Green" -fast

                Spawn-Module "Matrix"
                Start-Sleep -Seconds 3
            }
            2 {
                # Privilege Escalation
                Write-Host "`n  +============================================================+" -ForegroundColor Yellow
                Write-Host "  | PHASE 2: PRIVILEGE ESCALATION                             |" -ForegroundColor Yellow
                Write-Host "  +============================================================╝`n" -ForegroundColor Yellow

                Show-Educational "Privilege Escalation" "Attackers escalate from normal user to SYSTEM/Administrator using exploits like PrintNightmare or misconfigured services."

                Type-Text "  [+] Checking for privilege escalation vectors..." "Cyan" -fast
                Type-Text "  [+] CVE-2021-34527 (PrintNightmare) - VULNERABLE!" "Red" -fast
                Type-Text "  [+] Exploiting Print Spooler service..." "Yellow" -fast
                Show-HackProgress "ESCALATING TO NT AUTHORITY\SYSTEM" "Yellow" -realistic

                Type-Text "`n  [+] Privileges escalated successfully" "Green" -fast
                Type-Text "  [+] Current User: NT AUTHORITY\SYSTEM" "Green" -fast
                Play-Sound "access"

                Spawn-Module "Hex"
                Start-Sleep -Seconds 3
            }
            3 {
                # Credential Dumping
                Write-Host "`n  +============================================================+" -ForegroundColor Magenta
                Write-Host "  | PHASE 3: CREDENTIAL HARVESTING                            |" -ForegroundColor Magenta
                Write-Host "  +============================================================╝`n" -ForegroundColor Magenta

                Show-Educational "Credential Dumping" "Tools like Mimikatz extract credentials from memory. Defend with Credential Guard and monitor LSASS access."

                Type-Text "  [+] Dumping LSASS memory (lsass.exe PID: 724)..." "Cyan" -fast
                Type-Text "  [+] Using Mimikatz 2.2.0 (Kiwi Processor)" "Yellow" -fast
                Show-HackProgress "EXTRACTING CREDENTIALS FROM MEMORY" "Magenta" -realistic

                $creds = @(
                    "Administrator :: NTLM: 8846f7eaee8fb117ad06bdd830b7586c",
                    "DomainAdmin :: NTLM: 2b576acbe6bcfda7294d6bd18041b8fe",
                    "SQLService :: Kerberos: TGT obtained",
                    "BackupAdmin :: NTLM: 1130be98e96ba90823d4c4f8fc4d7c3e"
                )
                foreach ($cred in $creds) {
                    if (Should-Stop) { break }
                    Type-Text "  [+] $cred" "Green" -fast
                    Play-Sound "data"
                }

                Spawn-Module "Keylogger"
                Start-Sleep -Seconds 3
            }
            4 {
                # Lateral Movement
                Write-Host "`n  +============================================================+" -ForegroundColor Red
                Write-Host "  | PHASE 4: LATERAL MOVEMENT                                 |" -ForegroundColor Red
                Write-Host "  +============================================================╝`n" -ForegroundColor Red

                Show-Educational "Lateral Movement" "Pass-the-Hash, RDP hijacking, and PSExec allow attackers to move between systems. Use network segmentation and monitor for suspicious authentication."

                Type-Text "  [+] Initiating lateral movement via Pass-the-Hash..." "Yellow" -fast
                Type-Text "  [+] Target: FILE-SERVER-01 (10.0.2.15)" "Cyan" -fast
                Type-Text "  [+] Using PsExec for remote code execution..." "Yellow" -fast
                Show-HackProgress "COMPROMISING FILE-SERVER-01" "Red" -realistic

                Type-Text "`n  [+] Pivoting to Domain Controller..." "Cyan" -fast
                Type-Text "  [+] Exploiting MS14-068 (Kerberos Checksum Validation)" "Red" -fast
                Show-HackProgress "COMPROMISING DC-PRIMARY" "Red" -realistic

                Spawn-Module "LateralMovement"
                Start-Sleep -Seconds 3
            }
            5 {
                # Persistence
                Write-Host "`n  +============================================================+" -ForegroundColor DarkYellow
                Write-Host "  | PHASE 5: ESTABLISHING PERSISTENCE                         |" -ForegroundColor DarkYellow
                Write-Host "  +============================================================╝`n" -ForegroundColor DarkYellow

                Show-Educational "Persistence" "Attackers create backdoors via scheduled tasks, registry keys, or WMI event subscriptions to maintain access even after reboots."

                $persistence = @(
                    "Registry Run Key: HKLM\Software\Microsoft\Windows\CurrentVersion\Run\WindowsUpdate",
                    "Scheduled Task: \Microsoft\Windows\UpdateOrchestrator\SecurityPatch",
                    "WMI Event Subscription: ActiveScriptEventConsumer",
                    "Golden Ticket: Forged Kerberos TGT with 10-year lifetime",
                    "Service DLL Hijacking: wlbsctrl.dll (Print Spooler)"
                )
                foreach ($p in $persistence) {
                    if (Should-Stop) { break }
                    Type-Text "  [+] Installing: $p" "Yellow" -fast
                    Play-Sound "scanning"
                    Start-Sleep -Milliseconds 500
                }
                Type-Text "`n  [+] Persistence mechanisms deployed" "Green" -fast
                Play-Sound "success"

                Spawn-Module "Infection"
                Start-Sleep -Seconds 3
            }
            6 {
                # Data Exfiltration
                Write-Host "`n  +============================================================+" -ForegroundColor Cyan
                Write-Host "  | PHASE 6: DATA EXFILTRATION                                |" -ForegroundColor Cyan
                Write-Host "  +============================================================╝`n" -ForegroundColor Cyan

                Show-Educational "Data Exfiltration" "Sensitive data is stolen over encrypted channels. Monitor for unusual data transfers and use DLP solutions."

                Type-Text "  [+] Identifying high-value targets..." "Cyan" -fast
                Type-Text "  [+] Compressing and encrypting data..." "Yellow" -fast
                Show-HackProgress "STAGING DATA FOR EXFILTRATION" "Cyan" -realistic

                Type-Text "`n  [+] Establishing C2 channel (DNS tunneling)..." "Yellow" -fast
                Type-Text "  [+] C2 Server: c2.malicious-domain.com (TLS 1.3 encrypted)" "Red" -fast

                Spawn-Module "DataExfil"
                Start-Sleep -Seconds 3
            }
            7 {
                # Ransomware Deployment
                Write-Host "`n  +============================================================+" -ForegroundColor Red
                Write-Host "  | PHASE 7: RANSOMWARE DEPLOYMENT                            |" -ForegroundColor Red
                Write-Host "  +============================================================╝`n" -ForegroundColor Red

                Show-Educational "Ransomware" "Final stage: encrypt files and demand ransom. Prevention: backups, EDR, and segmentation. Never pay ransoms!"

                Type-Text "  [+] Deploying LockBit 3.0 ransomware variant..." "Red" -fast
                Type-Text "  [+] Disabling Windows Defender and backup services..." "Yellow" -fast
                Type-Text "  [+] Deleting Volume Shadow Copies..." "Red" -fast
                Show-HackProgress "ENCRYPTING ENTERPRISE DATA" "Red" -realistic

                Play-Sound "encryption"
                Spawn-Module "Ransomware"
                Start-Sleep -Seconds 3
            }
            8 {
                # Maximum Chaos
                Write-Host "`n  +============================================================+" -ForegroundColor White -BackgroundColor DarkRed
                Write-Host "  | PHASE 8: TOTAL NETWORK COMPROMISE                         |" -ForegroundColor White -BackgroundColor DarkRed
                Write-Host "  +============================================================╝`n" -ForegroundColor White

                Show-SystemAlert "CRITICAL BREACH" "ALL SYSTEMS COMPROMISED - CONTACT INCIDENT RESPONSE" "Red"

                Spawn-Module "Glitch"
                Spawn-Module "Map"
                Spawn-Module "Chat"
                Start-Sleep -Seconds 5
            }
            default {
                # Sustained Attack Mode
                Show-SystemAlert "SUSTAINED ATTACK" "APT MAINTAINING PRESENCE" "Red"
                $modules = @("Matrix", "Hex", "Map", "Keylogger", "DataExfil", "Ransomware", "Infection", "Glitch", "LateralMovement")
                if ((Get-Random -Max 3) -eq 0) { Spawn-Module (Get-Random $modules) }
                Start-Sleep -Seconds 5
            }
        }

        $phase++
        if ($phase -gt 15) { $phase = 15 } # Stay in sustained mode

        Move-Window-Random
        Start-Sleep -Seconds 2
    }
}

# ============================================================================
# CONSENT & DEBRIEF FUNCTIONS
# ============================================================================

function Show-Consent {
    Clear-Host
    Write-Host "`n`n"
    Write-Host "  +======================================================================+" -ForegroundColor Red
    Write-Host "  |                     !! WARNING - SYSTEM BREACH !!                    |" -ForegroundColor Red
    Write-Host "  +======================================================================+" -ForegroundColor Red
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  An Advanced Persistent Threat has been detected on this system.    |" -ForegroundColor White
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  The following attack vectors have been compromised:                |" -ForegroundColor White
    Write-Host "  |  - Network perimeter firewall                                       |" -ForegroundColor Gray
    Write-Host "  |  - Authentication systems                                           |" -ForegroundColor Gray
    Write-Host "  |  - Active Directory domain controllers                              |" -ForegroundColor Gray
    Write-Host "  |  - Endpoint protection services                                     |" -ForegroundColor Gray
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  ALERT: Multiple attack modules deploying...                        |" -ForegroundColor Yellow
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  Emergency Response:                                                |" -ForegroundColor Red
    Write-Host "  |  Type 'secret' in any window to activate emergency shutdown         |" -ForegroundColor Green
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  Attack Profile: $($global:config.Intensity.PadRight(51)) |" -ForegroundColor White
    Write-Host "  |  Threat Level: CRITICAL                                             |" -ForegroundColor Red
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  +======================================================================+" -ForegroundColor Red
    Write-Host "`n"

    $response = Read-Host "  Press ENTER to continue, or Ctrl+C to abort"
}

function Show-Debrief {
    Clear-Host
    Write-Host "`n`n"
    Write-Host "  +======================================================================+" -ForegroundColor Green
    Write-Host "  |              SECURITY AWARENESS TRAINING - DEBRIEF                   |" -ForegroundColor Green
    Write-Host "  +======================================================================+" -ForegroundColor Green
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  Key Takeaways from this Demonstration:                             |" -ForegroundColor White
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  1. Multi-Stage Attacks: Real attacks follow a kill chain           |" -ForegroundColor Cyan
    Write-Host "  |     Initial Access -> Escalation -> Persistence -> Exfiltration     |" -ForegroundColor Gray
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  2. Defense Strategies:                                             |" -ForegroundColor Cyan
    Write-Host "  |     - Keep systems patched (CVEs shown are real!)                   |" -ForegroundColor Gray
    Write-Host "  |     - Use EDR/XDR solutions to detect anomalies                     |" -ForegroundColor Gray
    Write-Host "  |     - Implement network segmentation                                |" -ForegroundColor Gray
    Write-Host "  |     - Enable MFA and Credential Guard                               |" -ForegroundColor Gray
    Write-Host "  |     - Maintain offline backups (ransomware protection)              |" -ForegroundColor Gray
    Write-Host "  |     - Security awareness training for all staff                     |" -ForegroundColor Gray
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  3. Incident Response:                                              |" -ForegroundColor Cyan
    Write-Host "  |     - Have an IR plan ready before an attack                        |" -ForegroundColor Gray
    Write-Host "  |     - Practice tabletop exercises regularly                         |" -ForegroundColor Gray
    Write-Host "  |     - Know your escalation contacts                                 |" -ForegroundColor Gray
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  |  4. Report Suspicious Activity:                                     |" -ForegroundColor Cyan
    Write-Host "  |     - If you see something unusual, report it immediately           |" -ForegroundColor Gray
    Write-Host "  |     - Don't click suspicious links or open unknown attachments      |" -ForegroundColor Gray
    Write-Host "  |     - Verify requests for sensitive information                     |" -ForegroundColor Gray
    Write-Host "  |                                                                      |" -ForegroundColor White
    Write-Host "  +======================================================================+" -ForegroundColor Green
    Write-Host "  |  Remember: Security is everyone's responsibility!                   |" -ForegroundColor Yellow
    Write-Host "  +======================================================================+" -ForegroundColor Green
    Write-Host "`n"

    Read-Host "  Press ENTER to exit"
}

# ============================================================================
# MAIN EXECUTION SWITCH
# ============================================================================

# ----------------------------------------------------------------------------
# SELF-HEALING & IEX SUPPORT
# ----------------------------------------------------------------------------
# If running via IEX (memory only), we must download/save ourselves to disk
# so we can spawn new windows.
$CurrentScript = $PSCommandPath
if (-not $CurrentScript) {
    try { $CurrentScript = (Get-Item $MyInvocation.MyCommand.Definition).FullName } catch {}
}

if (-not $CurrentScript -or -not (Test-Path $CurrentScript -ErrorAction SilentlyContinue)) {
    # We are running in memory (headless).
    # 1. Define a hidden temp location
    $TargetDir = "$env:TEMP\WindowsSecurityCache"
    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
    $CurrentScript = "$TargetDir\security_patch_kb40992.ps1"

    # 2. Download the script content to this file
    # (Using the URL provided for the raw script)
    $SelfUrl = "https://github.com/drakeaxelrod/unattended-windows-computer-prank/raw/refs/heads/main/prank.ps1"

    try {
        # Write-Host "Initializing Prank Protocol..." -ForegroundColor DarkGray
        Invoke-WebRequest -Uri $SelfUrl -OutFile $CurrentScript -UseBasicParsing
    } catch {
        Write-Host "Error: Could not retrieve payload. Check internet connection." -ForegroundColor Red
        exit
    }
}

# REMOVED: Start-Safety-Net (It was causing issues and is now integrated into Should-Stop)

if ($Module -eq "Launcher") {
    # Show consent screen if requested
    if ($ShowConsent) {
        Show-Consent
    }

    # Initial Launch - Force New Window using CMD START
    $intensityArg = "-Intensity `"$Intensity`""
    $modeArg = "-Mode `"$Mode`""
    $eduArg = if ($EducationalMode) { "-EducationalMode" } else { "" }
    $cmdArgs = "/c start `"CyberApocalypse`" powershell -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -File `"$CurrentScript`" -Module Master $intensityArg $modeArg $eduArg"
    Start-Process cmd -ArgumentList $cmdArgs -WindowStyle Hidden
    exit
}

try {
    # Main module dispatcher
    switch ($Module) {
        "Master" { Run-Master }
        "Matrix" { Run-Matrix }
        "Map" { Run-Map }
        "Hex" { Run-Hex }
        "Chat" { Run-Chat }
        "Infection" { Run-Infection }
        "Glitch" { Run-Glitch }
        "Ransomware" { Run-Ransomware }
        "Keylogger" { Run-Keylogger }
        "LateralMovement" { Run-LateralMovement }
        "DataExfil" { Run-DataExfil }
        default {
            Write-Host "Unknown module: $Module" -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            exit
        }
    }
}
catch {
    Write-Host "CRITICAL ERROR: $_" -ForegroundColor Red
    Write-Host "At Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}

# Cleanup and debrief
Clear-Host

# Show debrief if in Training mode (reveals it was training)
if ($global:config.Mode -eq "Training" -and $Module -eq "Master") {
    Show-Debrief
} else {
    Write-Host "`n  [ KILLSWITCH ACTIVATED ]" -ForegroundColor Yellow
    Write-Host "  [ EMERGENCY SHUTDOWN COMPLETE ]" -ForegroundColor Green
    Write-Host "`n  This was a security awareness training demonstration." -ForegroundColor Cyan
    Write-Host "  No actual harm occurred to your system." -ForegroundColor Cyan
    Start-Sleep -Seconds 3
}

exit