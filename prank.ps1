# ============================================================================
# CYBER APOCALYPSE - Hollywood Ultimate Hacking Prank
# ============================================================================
# WARNING: This spawns multiple windows! Type "S3cr3t" (no prompt) to stop!
# Press Ctrl+C won't save you... muahahaha!
# ============================================================================

param([switch]$child)

# Global flag file to stop all instances
$global:flagFile = "$env:TEMP\cyberApocalypseFlag.tmp"

# ASCII Banner
$banner = @"
   ██████╗██╗   ██╗██████╗ ███████╗██████╗      █████╗ ██████╗  ██████╗  ██████╗ █████╗ ██╗  ██╗   ██╗██████╗ ███████╗███████╗
  ██╔════╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██║  ╚██╗ ██╔╝██╔══██╗██╔════╝██╔════╝
  ██║      ╚████╔╝ ██████╔╝█████╗  ██████╔╝    ███████║██████╔╝██║   ██║██║     ███████║██║   ╚████╔╝ ██████╔╝███████╗█████╗
  ██║       ╚██╔╝  ██╔══██╗██╔══╝  ██╔══██╗    ██╔══██║██╔═══╝ ██║   ██║██║     ██╔══██║██║    ╚██╔╝  ██╔═══╝ ╚════██║██╔══╝
  ╚██████╗   ██║   ██████╔╝███████╗██║  ██║    ██║  ██║██║     ╚██████╔╝╚██████╗██║  ██║███████╗██║   ██║     ███████║███████╗
   ╚═════╝   ╚═╝   ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═╝  ╚═╝╚═╝      ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝     ╚══════╝╚══════╝
"@

# Set up console
$host.UI.RawUI.WindowTitle = "⚠️ CRITICAL SYSTEM BREACH - CONTAINMENT FAILED ⚠️"
$host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

# Color combinations
$colors = @('Red', 'Green', 'Yellow', 'Cyan', 'Magenta', 'White', 'DarkRed', 'DarkGreen', 'DarkYellow', 'DarkCyan')

# Fake computer names
$fakeComputers = @(
    "HR-SERVER-01", "FINANCE-DESK-17", "COFFEE-MACHINE-9000",
    "CEO-LAPTOP-OMEGA", "MAIL-SRV-ALPHA", "DEV-PC-42",
    "SECURITY-CAM-GRID", "DOOR-LOCK-SYSTEM", "POWER-GRID-MAIN",
    "BACKUP-GENERATOR", "CLIMATE-CONTROL", "ELEVATOR-MASTER",
    "JURASSIC-GATEWAY", "MAINFRAME-PRIME", "NUCLEAR-REACTOR-7"
)

# Dramatic messages
$messages = @(
    "Establishing DinoLink™ connection...",
    "Activating Chaos Network Mode...",
    "Uploading RetroVirus 2.0...",
    "Bypassing Quantum Firewall...",
    "Re-routing through DARKNET nodes...",
    "Overloading Security Subsystems...",
    "Spreading Neural Infection Sequence...",
    "Initializing T-Rex Overwatch Protocol...",
    "Engaging Jurassic Expansion Chamber...",
    "Extracting biometric databases...",
    "Cloning administrator privileges...",
    "Injecting polymorphic code...",
    "Establishing Command & Control...",
    "Deploying rootkit payload...",
    "Harvesting encryption keys..."
)

# Function to check if should stop
function Should-Stop {
    return (Test-Path $global:flagFile)
}

# Function to spawn new window
function Spawn-NewWindow {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" -child" -WindowStyle Normal
}

# Function to type text character by character
function Type-Text {
    param([string]$text, [string]$color = 'Green', [int]$speed = 20)
    foreach ($char in $text.ToCharArray()) {
        if (Should-Stop) { return }
        Write-Host $char -NoNewline -ForegroundColor $color
        Start-Sleep -Milliseconds $speed
    }
    Write-Host ""
}

# Function for matrix effect
function Show-Matrix {
    param([int]$lines = 15)
    for ($i = 0; $i -lt $lines; $i++) {
        if (Should-Stop) { return }
        $randomText = -join ((0..90) | ForEach-Object { Get-Random -InputObject @('0', '1', '█', '▓', '▒', '░', 'X', '*', '#', '>', '<', '/', '\', '|') })
        Write-Host $randomText -ForegroundColor (Get-Random -InputObject $colors)
        Start-Sleep -Milliseconds 15
    }
}

# Function for progress bar
function Show-HackProgress {
    param([string]$task, [string]$color = 'Cyan')
    Write-Host "`n[$task]" -ForegroundColor $color
    $progress = 0
    while ($progress -lt 100) {
        if (Should-Stop) { return }
        $progress += Get-Random -Minimum 5 -Maximum 20
        if ($progress -gt 100) { $progress = 100 }
        $bar = "█" * [math]::Floor($progress / 2)
        $space = "░" * (50 - [math]::Floor($progress / 2))
        Write-Host "`r$bar$space $progress%" -NoNewline -ForegroundColor $color
        Start-Sleep -Milliseconds (Get-Random -Minimum 30 -Maximum 150)
    }
    Write-Host "`r$('█' * 50) 100% COMPLETE" -ForegroundColor Green
}

# Function for system infection spread
function Show-InfectionSpread {
    param([int]$duration = 30)
    $startTime = Get-Date
    while (((Get-Date) - $startTime).TotalSeconds -lt $duration) {
        if (Should-Stop) { return }

        $remaining = $duration - [int]((Get-Date) - $startTime).TotalSeconds
        $pc = Get-Random $fakeComputers
        $msg = Get-Random $messages

        Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Red
        Write-Host ("║ SYSTEMS COMPROMISED: {0,-42} ║" -f "$remaining") -ForegroundColor Yellow
        Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Red
        Write-Host ("  ► TARGET: {0}" -f $pc) -ForegroundColor Cyan
        Write-Host ("  ► ACTION: {0}" -f $msg) -ForegroundColor Magenta

        # Random warnings
        if ($remaining % 7 -eq 0) {
            Write-Host "`n  ⚠️⚠️⚠️ CRITICAL NODE EXPANSION DETECTED ⚠️⚠️⚠️" -ForegroundColor DarkRed
        }

        # Access Denied throwback
        if ($remaining % 10 -eq 0) {
            Write-Host "`n           ╔═══════════════════╗" -ForegroundColor Red
            Write-Host "           ║  ACCESS DENIED    ║" -ForegroundColor Red
            Write-Host "           ║  ACCESS DENIED    ║" -ForegroundColor Red
            Write-Host "           ║  ACCESS DENIED    ║" -ForegroundColor Red
            Write-Host "           ╚═══════════════════╝" -ForegroundColor Red
        }

        Start-Sleep -Milliseconds 500
    }
}

# Background job to listen for secret password
function Start-PasswordListener {
    $scriptBlock = {
        param($flagFile)

        $password = ""
        $target = "S3cr3t"

        while ($true) {
            if (Test-Path $flagFile) { break }

            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $password += $key.KeyChar

                # Keep only last 6 characters
                if ($password.Length -gt 6) {
                    $password = $password.Substring($password.Length - 6)
                }

                # Check if password matches
                if ($password -eq $target) {
                    New-Item -Path $flagFile -ItemType File -Force | Out-Null
                    break
                }
            }

            Start-Sleep -Milliseconds 50
        }
    }

    Start-Job -ScriptBlock $scriptBlock -ArgumentList $global:flagFile | Out-Null
}

# Main execution
if (-not $child) {
    # Parent window - spawn children
    Clear-Host
    Write-Host $banner -ForegroundColor Red
    Write-Host "`n`n"
    Type-Text "  INITIATING MULTI-VECTOR ATTACK SEQUENCE..." "Red" 30
    Type-Text "  SPAWNING DISTRIBUTED PAYLOAD NODES..." "Yellow" 30
    Write-Host "`n"

    # Spawn 3 child windows
    for ($i = 1; $i -le 3; $i++) {
        Type-Text "  ► Launching Attack Vector $i..." "Cyan" 20
        Spawn-NewWindow
        Start-Sleep -Milliseconds 800
    }

    Type-Text "`n  ALL ATTACK VECTORS DEPLOYED!" "Green" 30
    Type-Text "  SYSTEM COMPROMISE IMMINENT..." "Red" 30
    Start-Sleep -Seconds 2
}

# Start password listener
Start-PasswordListener

# Main show loop
while (-not (Should-Stop)) {
    Clear-Host
    Write-Host $banner -ForegroundColor Red
    Write-Host "`n"
    Write-Host "  ╔════════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║       >>> WELCOME TO CYBER APOCALYPSE CONTROL SYSTEM <<<         ║" -ForegroundColor Yellow
    Write-Host "  ║          >>> CONTAINMENT HAS FAILED - CHAOS ENGAGED <<<          ║" -ForegroundColor Yellow
    Write-Host "  ╚════════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

    # Random sequence variations
    $sequence = Get-Random -Minimum 1 -Maximum 5

    switch ($sequence) {
        1 {
            Write-Host "`n  [PHASE 1: NETWORK INFILTRATION]`n" -ForegroundColor Cyan
            Show-Matrix -lines 10
            Show-HackProgress "PENETRATING FIREWALL" "Red"
            Show-HackProgress "ESCALATING PRIVILEGES" "Yellow"
        }
        2 {
            Write-Host "`n  [PHASE 2: DATA EXFILTRATION]`n" -ForegroundColor Magenta
            Show-InfectionSpread -duration 20
        }
        3 {
            Write-Host "`n  [PHASE 3: SYSTEM TAKEOVER]`n" -ForegroundColor Red

            $files = @(
                "//CLASSIFIED/GOVERNMENT/AREA51.DAT",
                "//TOPSECRET/MILITARY/LAUNCH_CODES.SYS",
                "//SYSTEM/ROOT/MASTER_KEY.DB",
                "//CORPORATE/CEO/BANK_ACCOUNTS.XLS",
                "//PERSONAL/PHOTOS/EMBARRASSING_PICS.ZIP"
            )

            foreach ($file in $files) {
                if (Should-Stop) { break }
                Type-Text "  ► ACCESSING: $file" "Red" 10
                Show-HackProgress "DOWNLOAD" (Get-Random -InputObject @('Red', 'Yellow', 'Magenta'))
            }
        }
        4 {
            Write-Host "`n  [PHASE 4: CHAOS PROPAGATION]`n" -ForegroundColor Yellow
            Show-Matrix -lines 20

            for ($i = 0; $i -lt 15; $i++) {
                if (Should-Stop) { break }
                $msg = Get-Random -InputObject @(
                    ">> DEPLOYING MALWARE TO NODE $i...",
                    ">> CORRUPTING DATABASE SECTOR $i...",
                    ">> HIJACKING CONTROL SYSTEM $i...",
                    ">> ESTABLISHING BACKDOOR $i..."
                )
                Write-Host $msg -ForegroundColor (Get-Random -InputObject $colors)
                Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 300)
            }
        }
    }

    # Dramatic countdown
    if (-not (Should-Stop)) {
        Write-Host "`n`n  [TOTAL SYSTEM LOCKDOWN IMMINENT]`n" -ForegroundColor Red
        for ($i = 10; $i -gt 0; $i--) {
            if (Should-Stop) { break }
            Write-Host "`r  ⚠️  CATASTROPHIC FAILURE IN: $i SECONDS  ⚠️  " -NoNewline -ForegroundColor Red -BackgroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }

    if (-not (Should-Stop)) {
        Show-Matrix -lines 25
        Start-Sleep -Seconds 1
    }
}

# Cleanup and exit
Clear-Host
Write-Host "`n`n`n"
Write-Host "  ╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                                                ║" -ForegroundColor Green
Write-Host "  ║              ✓ SECRET CODE ACCEPTED ✓                         ║" -ForegroundColor Green
Write-Host "  ║                                                                ║" -ForegroundColor Green
Write-Host "  ║              CYBER APOCALYPSE TERMINATED                       ║" -ForegroundColor Green
Write-Host "  ║              ALL SYSTEMS RESTORED                              ║" -ForegroundColor Green
Write-Host "  ║                                                                ║" -ForegroundColor Green
Write-Host "  ║              Just kidding! This was a prank! 🎭               ║" -ForegroundColor Cyan
Write-Host "  ║              No actual hacking occurred.                       ║" -ForegroundColor Cyan
Write-Host "  ║                                                                ║" -ForegroundColor Green
Write-Host "  ╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

# Cleanup
if (Test-Path $global:flagFile) {
    Remove-Item $global:flagFile -Force -ErrorAction SilentlyContinue
}

Get-Job | Remove-Job -Force

Write-Host "`n  Thanks for playing! This window will close in 5 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 5
