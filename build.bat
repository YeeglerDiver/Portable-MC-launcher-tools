@echo off
cd /d "%APPDATA%\.minecraft"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -Raw -LiteralPath '%~f0') -split ('::PS'+'BEGIN'))[1]"
echo.
pause
exit /b

::PSBEGIN
$ErrorActionPreference = 'Stop'
try {
  $v = "26.3"
  $dst = "OfflineMC\game"

  if (-not (Test-Path rip.ps1)) { throw "rip.ps1 not found in $PWD" }
  if (-not (Select-String -Path rip.ps1 -Pattern 'Player name' -Quiet)) { throw "rip.ps1 is not the launcher script (no 'Player name' prompt). Restore the launcher first." }
  if (-not (Test-Path build-portable.ps1)) { throw "build-portable.ps1 not found in $PWD. Save the build script there first." }

  $jdk = Get-ChildItem "C:\Program Files\Eclipse Adoptium" -Directory -Filter "jdk-25*" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $jdk) { throw "Java 25 not found. Run: winget install EclipseAdoptium.Temurin.25.JDK" }

  Write-Host "[1/6] Installing/loading ps2exe..."
  if (-not (Get-Module -ListAvailable ps2exe)) {
    Install-PackageProvider NuGet -Force -Scope CurrentUser | Out-Null
    Install-Module ps2exe -Scope CurrentUser -Force
  }
  Import-Module ps2exe

  Write-Host "[2/6] Compiling launcher..."
  Remove-Item OfflineMC, payload.zip, Stub.cs, OfflineMC-Portable.exe -Recurse -Force -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force "$dst\versions" | Out-Null
  Invoke-PS2EXE -inputFile rip.ps1 -outputFile OfflineMC\OfflineMC.exe -STA | Out-Null
  if (-not (Test-Path OfflineMC\OfflineMC.exe)) { throw "ps2exe did not produce OfflineMC.exe" }

  Write-Host "[3/6] Copying version $v..."
  Copy-Item "versions\$v" "$dst\versions\$v" -Recurse

  Write-Host "[4/6] Copying Java..."
  New-Item -ItemType Directory -Force OfflineMC\java | Out-Null
  Copy-Item "$($jdk.FullName)\*" OfflineMC\java -Recurse
  Remove-Item OfflineMC\java\jmods -Recurse -Force -ErrorAction SilentlyContinue
  Remove-Item OfflineMC\java\lib\src.zip -Force -ErrorAction SilentlyContinue
  if (-not (Test-Path OfflineMC\java\bin\java.exe)) { throw "java.exe missing from bundle" }

  Write-Host "[5/6] Copying only the libraries and assets $v needs..."
  $j = Get-Content "versions\$v\$v.json" -Raw | ConvertFrom-Json
  foreach ($lib in $j.libraries) {
    if ($lib.downloads.artifact) {
      $p = $lib.downloads.artifact.path -replace '/','\'
      if (Test-Path "libraries\$p") {
        New-Item -ItemType Directory -Force (Split-Path "$dst\libraries\$p") | Out-Null
        Copy-Item "libraries\$p" "$dst\libraries\$p"
      }
    }
  }
  $id = $j.assetIndex.id
  New-Item -ItemType Directory -Force "$dst\assets\indexes" | Out-Null
  Copy-Item "assets\indexes\$id.json" "$dst\assets\indexes\"
  $idx = Get-Content "assets\indexes\$id.json" -Raw | ConvertFrom-Json
  foreach ($o in $idx.objects.PSObject.Properties) {
    $h = $o.Value.hash; $s = $h.Substring(0,2)
    New-Item -ItemType Directory -Force "$dst\assets\objects\$s" | Out-Null
    Copy-Item "assets\objects\$s\$h" "$dst\assets\objects\$s\" -ErrorAction SilentlyContinue
  }

  Write-Host "[6/6] Running build-portable.ps1 (zipping + compiling, takes a while)..."
  & .\build-portable.ps1

  if (Test-Path payload.zip) {
    $pz = (Get-Item payload.zip).Length
    if ($pz -ge 2000MB) { throw ("payload.zip is {0:N2} GB, over the ~2 GB limit, so the exe will not run." -f ($pz / 1GB)) }
  }
  if (-not (Test-Path OfflineMC-Portable.exe)) { throw "OfflineMC-Portable.exe was not created" }

  $mb = [math]::Round((Get-Item OfflineMC-Portable.exe).Length / 1MB)
  Write-Host "Done! $PWD\OfflineMC-Portable.exe ($mb MB)" -ForegroundColor Green
}
catch {
  Write-Host "ERROR: $($_ | Out-String)" -ForegroundColor Red
}