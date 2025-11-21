# ============================================================================
# CYBER APOCALYPSE: OMEGA PROTOCOL - ENHANCED EDITION
# ============================================================================
# A Hollywood-style security awareness training demonstration script.
#
# WARNING: FOR AUTHORIZED SECURITY AWARENESS TRAINING ONLY
# SAFE TO USE: Press ESC, Ctrl+C, or type "secret" to terminate.
#
# PURPOSE: Educational tool to demonstrate attack scenarios in training
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

# Global Configuration
$global:flagFile = "$env:TEMP\cyberApocalypseFlag.tmp"
$global:inputBuffer = ""
$global:pauseFlag = "$env:TEMP\cyberApocalypsePause.tmp"
$global:sessionLog = @()

# Intensity-based configuration
$global:config = @{
    Intensity = $Intensity
    Mode = $Mode
    SpawnDelay = switch ($Intensity) {
        "Mild" { 10 }
        "Moderate" { 5 }
        "Hollywood" { 2 }
    }
    WindowMovementFrequency = switch ($Intensity) {
        "Mild" { 200 }  # Rarely move windows
        "Moderate" { 100 }
        "Hollywood" { 30 }  # Move windows aggressively
    }
    TypeSpeed = switch ($Intensity) {
        "Mild" { 40 }
        "Moderate" { 25 }
        "Hollywood" { 15 }
    }
    MaxModules = switch ($Intensity) {
        "Mild" { 3 }
        "Moderate" { 6 }
        "Hollywood" { 12 }
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
    # 1. Check for multiple killswitch methods
    if ($host.UI.RawUI.KeyAvailable) {
        $k = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        # ESC key detection (VirtualKeyCode 27)
        if ($k.VirtualKeyCode -eq 27) {
            Write-Host "`n[!] ESC pressed - Initiating shutdown..." -ForegroundColor Yellow
            New-Item -Path $global:flagFile -ItemType File -Force | Out-Null
            return $true
        }

        # Ctrl+C detection (Character 3)
        if ($k.Character -eq 3) {
            Write-Host "`n[!] Ctrl+C detected - Terminating..." -ForegroundColor Yellow
            New-Item -Path $global:flagFile -ItemType File -Force | Out-Null
            return $true
        }

        # Secret word detection
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
                Write-Host "`n[▶] RESUMED" -ForegroundColor Green
            } else {
                New-Item -Path $global:pauseFlag -ItemType File -Force | Out-Null
                Write-Host "`n[⏸] PAUSED - Press P to continue, ESC to quit" -ForegroundColor Yellow
            }
        }
    }

    # 2. Check if flag file exists
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
    param([string]$name)
    if (Should-Stop) { return }

    # Check if we've hit the module limit
    if ($Generation -ge $global:config.MaxModules) { return }

    # Use CMD START to force a new window detached from the parent, passing through config
    $intensityArg = "-Intensity `"$($global:config.Intensity)`""
    $modeArg = "-Mode `"$($global:config.Mode)`""
    $cmdArgs = "/c start `"$name`" powershell -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -File `"$PSCommandPath`" -Module $name -Generation $($Generation + 1) $intensityArg $modeArg"
    Start-Process cmd -ArgumentList $cmdArgs -WindowStyle Hidden

    # Respect spawn delay based on intensity
    Start-Sleep -Seconds $global:config.SpawnDelay
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
  ██████╗ ██████╗ ███████╗ █████╗  ██████╗██╗  ██╗
  ██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝██║  ██║
  ██████╔╝██████╔╝█████╗  ███████║██║     ███████║
  ██╔══██╗██╔══██╗██╔══╝  ██╔══██║██║     ██╔══██║
  ██████╔╝██║  ██║███████╗██║  ██║╚██████╗██║  ██║
  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
"@
        "Ransomware" = @"
  ██████╗  █████╗ ███╗   ██╗███████╗ ██████╗ ███╗   ███╗
  ██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔═══██╗████╗ ████║
  ██████╔╝███████║██╔██╗ ██║███████╗██║   ██║██╔████╔██║
  ██╔══██╗██╔══██║██║╚██╗██║╚════██║██║   ██║██║╚██╔╝██║
  ██║  ██║██║  ██║██║ ╚████║███████║╚██████╔╝██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝
"@
        "Omega" = @"
   ██████╗ ███╗   ███╗███████╗ ██████╗  █████╗
  ██╔═══██╗████╗ ████║██╔════╝██╔════╝ ██╔══██╗
  ██║   ██║██╔████╔██║█████╗  ██║  ███╗███████║
  ██║   ██║██║╚██╔╝██║██╔══╝  ██║   ██║██╔══██║
  ╚██████╔╝██║ ╚═╝ ██║███████╗╚██████╔╝██║  ██║
   ╚═════╝ ╚═╝     ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
"@
    }

    if ($banners.ContainsKey($type)) {
        Write-Host $banners[$type] -ForegroundColor Red
    }
}

function Show-Educational {
    param([string]$title, [string]$message)

    if (-not $EducationalMode) { return }

    Write-Host "`n╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Blue
    Write-Host "║ 📚 TRAINING NOTE: $($title.PadRight(44)) ║" -ForegroundColor Cyan
    Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Blue

    # Word wrap the message
    $words = $message -split ' '
    $line = "║ "
    foreach ($word in $words) {
        if (($line.Length + $word.Length) -gt 61) {
            Write-Host ($line.PadRight(63) + "║") -ForegroundColor White
            $line = "║ $word "
        } else {
            $line += "$word "
        }
    }
    if ($line.Length -gt 2) {
        Write-Host ($line.PadRight(63) + "║") -ForegroundColor White
    }

    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Blue
    Start-Sleep -Seconds 3
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
            $bar = "█" * $filled
            $space = "░" * $empty

            Write-Host "`r  $bar$space $progress% - $($step.msg)" -NoNewline -ForegroundColor $color
            if ((Get-Random -Max 10) -eq 0) { Play-Sound "scanning" }
            Start-Sleep -Milliseconds (Get-Random -Minimum $baseDelay -Maximum $maxDelay)
        }
    }

    Write-Host "`r  $('█' * 50) 100% ✓ COMPLETE                    " -ForegroundColor Green
    Play-Sound "success"
}

function Show-SystemAlert {
    param([string]$title, [string]$message, [string]$color="Red")
    $width = 60
    $padding = [math]::Floor(($width - $message.Length) / 2)
    $padStr = " " * $padding
    Write-Host "`n"
    Write-Host "  ╔$([string]('═' * $width))╗" -ForegroundColor $color
    Write-Host "  ║$([string](' ' * $width))║" -ForegroundColor $color
    Write-Host "  ║$padStr$message$padStr ║" -ForegroundColor White -BackgroundColor $color
    Write-Host "  ║$([string](' ' * $width))║" -ForegroundColor $color
    Write-Host "  ╚$([string]('═' * $width))╝" -ForegroundColor $color
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

        Write-Host "`n╔═══════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "║         YOUR FILES HAVE BEEN ENCRYPTED - PAY 5 BTC NOW!          ║" -ForegroundColor White -BackgroundColor DarkRed
        Write-Host "╚═══════════════════════════════════════════════════════════════════╝" -ForegroundColor Red

        # Countdown timer
        $timeLeft = 300 - (Get-Random -Max 150)
        Write-Host "`n  ⏰ Time until files are permanently deleted: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($timeLeft) seconds" -ForegroundColor Red -BackgroundColor Black
        Play-Sound "countdown"

        Write-Host "`n  📊 Encryption Progress:`n" -ForegroundColor Cyan

        # Simulate file encryption
        foreach ($i in 1..8) {
            if (Should-Stop) { return }
            $path = Get-Random $fakePaths
            $type = Get-Random $fileTypes
            $count = Get-Random -Min 10 -Max 500

            Write-Host "  [" -NoNewline -ForegroundColor DarkGray
            Write-Host "✓" -NoNewline -ForegroundColor Red
            Write-Host "] $path\$type ($count files) " -NoNewline -ForegroundColor Gray
            Write-Host "ENCRYPTED" -ForegroundColor Red

            Play-Sound "encryption"
            Start-Sleep -Milliseconds 800
        }

        Write-Host "`n  💰 Bitcoin Address: 1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" -ForegroundColor Yellow
        Write-Host "  📧 Contact: decrypt@evilhackers.onion`n" -ForegroundColor Yellow

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

        Write-Host "`n  ╔══════════════════════════════════════════════════╗" -ForegroundColor DarkMagenta
        Write-Host "  ║    KEYLOGGER ACTIVE - CAPTURING ALL INPUT       ║" -ForegroundColor Magenta
        Write-Host "  ╚══════════════════════════════════════════════════╝`n" -ForegroundColor DarkMagenta

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

        Write-Host "`n  📡 Uploading captured data to C2 server..." -ForegroundColor Red
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

        Write-Host "`n  ═══════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  🌐 NETWORK PENETRATION - LATERAL MOVEMENT IN PROGRESS" -ForegroundColor Yellow
        Write-Host "  ═══════════════════════════════════════════════════════`n" -ForegroundColor Cyan

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

        Write-Host "`n  🎯 Current Technique: " -NoNewline -ForegroundColor Cyan
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

        Write-Host "`n  ╔════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host "  ║   DATA EXFILTRATION IN PROGRESS - DO NOT SHUT DOWN   ║" -ForegroundColor White
        Write-Host "  ╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Red

        $target = Get-Random $dataTypes
        $server = Get-Random $c2Servers

        Write-Host "  📁 File: " -NoNewline -ForegroundColor Cyan
        Write-Host $target.name -ForegroundColor Yellow
        Write-Host "  📊 Size: " -NoNewline -ForegroundColor Cyan
        Write-Host $target.size -ForegroundColor White
        Write-Host "  ⚠️  Sensitivity: " -NoNewline -ForegroundColor Cyan
        $sensColor = if ($target.sensitivity -eq "CRITICAL") { "Red" } elseif ($target.sensitivity -eq "HIGH") { "Yellow" } else { "White" }
        Write-Host $target.sensitivity -ForegroundColor $sensColor
        Write-Host "  🌐 C2 Server: " -NoNewline -ForegroundColor Cyan
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
            $bar = "█" * $filled + "░" * $empty

            $speed = Get-Random -Min 800 -Max 2500
            Write-Host "`r  $bar $percent% ($speed KB/s)" -NoNewline -ForegroundColor Green

            if ((Get-Random -Max 5) -eq 0) { Play-Sound "data" }
            Start-Sleep -Milliseconds (Get-Random -Min 200 -Max 500)
        }

        Write-Host "`n  ✓ Upload complete - File staged for extraction`n" -ForegroundColor Green
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
            Write-Host "`n  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
            Write-Host ("  ║ ⚠️  INFECTION SPREADING - NODES COMPROMISED: {0,-15} ║" -f "$remaining") -ForegroundColor Yellow
            Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
            Write-Host ("    ► TARGET NODE: {0}" -f $pc) -ForegroundColor Cyan
            Write-Host ("    ► STATUS: {0}" -f $msg) -ForegroundColor Magenta
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
            $glitchText = -join ((0..120) | ForEach-Object { Get-Random -InputObject @('█', '▓', '▒', '░', '/', '\', '|', '-', 'X', '⚡', '☠', '☢') })
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
    while (-not (Should-Stop)) {
        Should-Pause
        $line = -join ((0..80) | % { if((Get-Random -Max 5) -eq 0) { [char](Get-Random -Min 33 -Max 126) } else { " " } })
        Write-Host $line -ForegroundColor Green
        Start-Sleep -Milliseconds 50
        if ((Get-Random -Max 50) -eq 0) { Move-Window-Random }
    }
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

    # 2. The Breach
    Clear-Host
    Write-Host "`n`n"
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║     CRITICAL SECURITY ALERT - UNAUTHORIZED ROOT ACCESS DETECTED      ║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Play-Sound "alert"
    Start-Sleep -Seconds 2

    Type-Text "  > INITIATING LOCKDOWN PROTOCOL..." "Red" 30
    Type-Text "  > FAILED. ACCESS DENIED." "Red" 30
    Type-Text "  > OMEGA AI TAKING CONTROL." "Yellow" 50

    # 3. The Story Loop
    $phase = 1
    while (-not (Should-Stop)) {
        Clear-Host
        Write-Host "`n  [ SYSTEM STATUS: CRITICAL - PHASE $phase ]" -ForegroundColor Red

        switch ($phase) {
            1 {
                Write-Host "`n  [🔴 PHASE 1: NETWORK INFILTRATION 🔴]`n" -ForegroundColor Cyan
                Spawn-Module "Matrix"
                Show-HackProgress "PENETRATING FIREWALL" "Red" -fast
                Show-HackProgress "ESCALATING PRIVILEGES" "Yellow" -fast
            }
            2 {
                Write-Host "`n  [💀 PHASE 2: DATA EXFILTRATION 💀]`n" -ForegroundColor Magenta
                Spawn-Module "Infection"
                Show-HackProgress "BYPASSING IDS/IPS" "Magenta" -fast
                Start-Sleep -Seconds 5
            }
            3 {
                Write-Host "`n  [⚡ PHASE 3: TOTAL SYSTEM TAKEOVER ⚡]`n" -ForegroundColor Red
                Spawn-Module "Hex"
                $files = @("//CLASSIFIED/AREA51.DAT", "//TOPSECRET/LAUNCH_CODES.SYS", "//SYSTEM/ROOT/MASTER_KEY.DB")
                foreach ($file in $files) {
                    if (Should-Stop) { break }
                    Type-Text "    ► ACCESSING: $file" "Red" 8 -glitch
                    Show-HackProgress "DOWNLOAD" "Yellow" -fast
                }
            }
            4 {
                Write-Host "`n  [🔥 PHASE 4: CHAOS PROPAGATION 🔥]`n" -ForegroundColor Yellow
                Spawn-Module "Glitch"
                Show-SystemAlert "WARNING" "VISUAL CORTEX OVERLOAD" "DarkRed"
                Start-Sleep -Seconds 5
            }
            5 {
                Write-Host "`n  [🌐 PHASE 5: GLOBAL INFECTION 🌐]`n" -ForegroundColor Cyan
                Spawn-Module "Map"
                Show-HackProgress "ESTABLISHING BOTNET" "Green" -fast
            }
            6 {
                Write-Host "`n  [👁️ PHASE 6: SURVEILLANCE 👁️]`n" -ForegroundColor DarkYellow
                Spawn-Module "Chat"
                Type-Text "  ► ACTIVATING WEBCAM..." "Yellow" 12
                Type-Text "  ► ACTIVATING MICROPHONE..." "Yellow" 12
                Start-Sleep -Seconds 5
            }
            default {
                # Chaos Mode
                Show-SystemAlert "CRITICAL ERROR" "SYSTEM INTEGRITY COMPROMISED" "Red"
                if ((Get-Random -Max 3) -eq 0) { Spawn-Module (Get-Random "Matrix","Hex","Map","Chat","Infection","Glitch") }
            }
        }

        $phase++
        if ($phase -gt 10) { $phase = 10 } # Stay in chaos mode

        Move-Window-Random
        Start-Sleep -Seconds 2
    }
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
    # Initial Launch - Force New Window using CMD START (Nuclear Option for Detaching)
    # We use the resolved $CurrentScript path which now definitely exists on disk.
    # Changed WindowStyle to Normal to avoid "Maximized" movement glitches.
    Start-Process cmd -ArgumentList "/c start `"CyberApocalypse`" powershell -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -File `"$CurrentScript`" -Module Master" -WindowStyle Hidden
    exit
}

try {
    # Remove the old Start-Safety-Net call as it's now integrated into Should-Stop
    # Start-Safety-Net

    if ($Module -eq "Master") { Run-Master }
    elseif ($Module -eq "Matrix") { Run-Matrix }
    elseif ($Module -eq "Map") { Run-Map }
    elseif ($Module -eq "Hex") { Run-Hex }
    elseif ($Module -eq "Chat") { Run-Chat }
    elseif ($Module -eq "Infection") { Run-Infection }
    elseif ($Module -eq "Glitch") { Run-Glitch }
}
catch {
    Write-Host "CRITICAL ERROR: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}

# Cleanup if stopped
Clear-Host
Write-Host "`n  [ SYSTEM RESTORED ]" -ForegroundColor Green
Write-Host "  [ PRANK TERMINATED ]" -ForegroundColor Green
Start-Sleep -Seconds 2
exit