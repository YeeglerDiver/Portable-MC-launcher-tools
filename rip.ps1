try {
  Add-Type -AssemblyName System.Windows.Forms
  Add-Type -AssemblyName System.IO.Compression.FileSystem

  $base = [AppContext]::BaseDirectory
  $mc = if (Test-Path "$base\game") { "$base\game" } else { "$env:APPDATA\.minecraft" }
  $v = "26.3"
  $java = if (Test-Path "$base\java\bin\java.exe") { "$base\java\bin\java.exe" } else { "java" }
  $utf8 = New-Object Text.UTF8Encoding($false)

  $name = Read-Host "Player name"
  if (-not $name) { $name = "Player" }

  $fd = New-Object System.Windows.Forms.OpenFileDialog
  $fd.Filter = "PNG skin (*.png)|*.png"
  $fd.Title = "Pick your skin PNG (Cancel to skip)"

  if ($fd.ShowDialog() -eq 'OK') {
    $pack = "$mc\resourcepacks\OfflineSkin"
    if (Test-Path $pack) { Remove-Item $pack -Recurse -Force }
    New-Item -ItemType Directory -Force $pack | Out-Null

    $zip = [IO.Compression.ZipFile]::OpenRead("$mc\versions\$v\$v.jar")

    $e = $zip.GetEntry('pack.mcmeta')
    if ($e) {
      $rd = New-Object IO.StreamReader($e.Open())
      $meta = $rd.ReadToEnd(); $rd.Close()
      $meta = $meta -replace '"description"\s*:\s*"[^"]*"', '"description":"Offline skin"'
    } else {
      $rd = New-Object IO.StreamReader($zip.GetEntry('version.json').Open())
      $vj = $rd.ReadToEnd() | ConvertFrom-Json; $rd.Close()
      $major = $null
      if ($vj.pack_version.resource_major) { $major = [int]$vj.pack_version.resource_major }
      elseif ($vj.resource_pack_version) { $major = [int]$vj.resource_pack_version }
      if ($major) { $lo = $major; $hi = $major } else { $lo = 1; $hi = 9999 }
      $meta = "{`"pack`":{`"description`":`"Offline skin`",`"min_format`":$lo,`"max_format`":$hi}}"
    }
    [IO.File]::WriteAllText("$pack\pack.mcmeta", $meta, $utf8)

    foreach ($en in $zip.Entries) {
      if ($en.FullName -match '^assets/minecraft/textures/entity/.*(steve|alex|ari|efe|kai|makena|noor|sunny|zuri)\.png$') {
        $dest = Join-Path $pack ($en.FullName -replace '/','\')
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        Copy-Item $fd.FileName $dest -Force
      }
    }
    $zip.Dispose()

    $opt = "$mc\options.txt"
    $line = 'resourcePacks:["vanilla","file/OfflineSkin"]'
    if (Test-Path $opt) {
      $txt = [IO.File]::ReadAllLines($opt)
      if ($txt -match '^resourcePacks:') { $txt = $txt -replace '^resourcePacks:.*', $line } else { $txt += $line }
      [IO.File]::WriteAllLines($opt, $txt, $utf8)
    } else {
      [IO.File]::WriteAllLines($opt, @($line), $utf8)
    }
  }

  $j = Get-Content "$mc\versions\$v\$v.json" -Raw | ConvertFrom-Json
  $cp = @()
  foreach ($lib in $j.libraries) {
    $ok = $true
    if ($lib.rules) {
      $ok = $false
      foreach ($r in $lib.rules) {
        if ((-not $r.os) -or ($r.os.name -eq 'windows')) { $ok = ($r.action -eq 'allow') }
      }
    }
    if ($ok -and $lib.downloads.artifact) { $cp += "$mc\libraries\" + ($lib.downloads.artifact.path -replace '/','\') }
  }
  $cp += "$mc\versions\$v\$v.jar"

  & $java -Xmx4G --enable-native-access=ALL-UNNAMED "-Djava.library.path=$mc\versions\$v\natives" -cp ($cp -join ';') $j.mainClass `
    --username $name --version $v --gameDir $mc --assetsDir "$mc\assets" `
    --assetIndex $j.assetIndex.id --accessToken 0
}
catch {
  Write-Host "SCRIPT ERROR: $($_ | Out-String)" -ForegroundColor Red
}
Read-Host "Press Enter to close"