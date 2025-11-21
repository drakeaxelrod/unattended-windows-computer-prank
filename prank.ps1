# ============================================================================
# CYBER APOCALYPSE: OMEGA PROTOCOL
# ============================================================================
# A Hollywood-style prank script for Windows.
# SAFE TO USE: Type "secret" in ANY window to kill all processes.
# ============================================================================

param(
    [string]$Module = "Launcher",  # Launcher, Master, Matrix, Map, Hex, Chat, Glitch
    [int]$Generation = 0
)

# Global Configuration
$global:flagFile = "$env:TEMP\cyberApocalypseFlag.tmp"
# ============================================================================
# CORE UTILITIES
# ============================================================================

function Should-Stop {
    return (Test-Path $global:flagFile)
}

function Play-Sound {
    param([string]$type)
    if ($type -eq "type") { [console]::beep(1200, 20) }
    if ($type -eq "alert") { [console]::beep(500, 300); [console]::beep(500, 300) }
    if ($type -eq "error") { [console]::beep(200, 400) }
    if ($type -eq "success") { [console]::beep(1000, 100); [console]::beep(1500, 100) }
    if ($type -eq "data") { [console]::beep((Get-Random -Min 800 -Max 2000), 10) }
    if ($type -eq "boot") { [console]::beep(400, 200); Start-Sleep -m 50; [console]::beep(600, 200) }
}

function Type-Text {
    param([string]$text, [string]$color = 'Green', [int]$speed = 20, [switch]$glitch)
    foreach ($char in $text.ToCharArray()) {
        if (Should-Stop) { return }
        if ($glitch -and (Get-Random -Max 20) -eq 0) {
            Write-Host ([char](Get-Random -Min 33 -Max 126)) -NoNewline -ForegroundColor (Get-Random $global:colors)
            Start-Sleep -m 10
            Write-Host "`b" -NoNewline
        }
        Write-Host $char -NoNewline -ForegroundColor $color
        if ($char -ne ' ') { Play-Sound "type" }
        Start-Sleep -Milliseconds $speed
    }
    Write-Host ""
}

function Spawn-Module {
    param([string]$name)
    if (Should-Stop) { return }
    Start-Process conhost.exe -ArgumentList "powershell.exe -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -File `"$PSCommandPath`" -Module $name -Generation $($Generation + 1)"
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
    param([string]$task, [string]$color = 'Cyan', [switch]$fast)
    Write-Host "`n  [$task]" -ForegroundColor $color
    $progress = 0
    $maxDelay = if ($fast) { 50 } else { 100 }
    while ($progress -lt 100) {
        if (Should-Stop) { return }
        $progress += Get-Random -Minimum 2 -Maximum 15
        if ($progress -gt 100) { $progress = 100 }
        $width = 50
        $filled = [math]::Floor(($progress / 100) * $width)
        $empty = $width - $filled
        $bar = "█" * $filled
        $space = "░" * $empty
        Write-Host "`r  $bar$space $progress%" -NoNewline -ForegroundColor $color
        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum $maxDelay)
    }
    Write-Host "`r  $('█' * 50) 100% ✓ COMPLETE" -ForegroundColor Green
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
# MODULES
# ============================================================================

function Run-Infection {
    $host.UI.RawUI.WindowTitle = "VIRUS_PROPAGATION_UNIT"
    $fakeComputers = @("HR-SERVER-01", "FINANCE-DESK-17", "CEO-LAPTOP-OMEGA", "MAIL-SRV-ALPHA", "DEV-PC-42", "SECURITY-CAM-GRID", "POWER-GRID-MAIN", "NUCLEAR-REACTOR-7")
    $messages = @("Injecting Payload...", "Bypassing Firewall...", "Corrupting MBR...", "Exfiltrating Passwords...", "Encrypting Drive...")

    while (-not (Should-Stop)) {
        Clear-Host
        $duration = 20
        $startTime = Get-Date
        while (((Get-Date) - $startTime).TotalSeconds -lt $duration) {
            if (Should-Stop) { return }
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

Start-Safety-Net

if ($Module -eq "Launcher") {
    # Initial Launch - Force New Window
    Start-Process conhost.exe -ArgumentList "powershell.exe -ExecutionPolicy Bypass -NoExit -WindowStyle Normal -File `"$PSCommandPath`" -Module Master"
    exit
}
elseif ($Module -eq "Master") { Run-Master }
elseif ($Module -eq "Matrix") { Run-Matrix }
elseif ($Module -eq "Map") { Run-Map }
elseif ($Module -eq "Hex") { Run-Hex }
elseif ($Module -eq "Chat") { Run-Chat }
elseif ($Module -eq "Infection") { Run-Infection }
elseif ($Module -eq "Glitch") { Run-Glitch }

# Cleanup if stopped
Clear-Host
Write-Host "`n  [ SYSTEM RESTORED ]" -ForegroundColor Green
Write-Host "  [ PRANK TERMINATED ]" -ForegroundColor Green
Start-Sleep -Seconds 2
exit