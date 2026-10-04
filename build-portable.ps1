$src = Join-Path (Get-Location) "OfflineMC"
$zip = Join-Path (Get-Location) "payload.zip"
$cs  = Join-Path (Get-Location) "Stub.cs"
$out = Join-Path (Get-Location) "OfflineMC-Portable.exe"
$csc = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path "$src\OfflineMC.exe")) { throw "Missing $src\OfflineMC.exe" }
if (-not (Test-Path "$src\java\bin\java.exe")) { Write-Warning "No java\bin\java.exe found, so it will need Java 25 installed on the PC." }

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $zip) { Remove-Item $zip -Force }
Write-Host "Zipping (this takes a while)..."
[IO.Compression.ZipFile]::CreateFromDirectory($src, $zip, [IO.Compression.CompressionLevel]::Fastest, $false)

$build = [DateTime]::UtcNow.Ticks.ToString()
$code = @'
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;

class P {
  static int Main() {
    string target = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "OfflineMC");
    string marker = Path.Combine(target, ".build");
    string build = "__BUILD__";
    Assembly asm = Assembly.GetExecutingAssembly();

    if (!File.Exists(marker) || File.ReadAllText(marker) != build) {
      Console.WriteLine("Unpacking game files (first run takes a minute)...");
      Directory.CreateDirectory(target);
      using (Stream s = asm.GetManifestResourceStream("payload.zip"))
      using (ZipArchive z = new ZipArchive(s, ZipArchiveMode.Read)) {
        foreach (ZipArchiveEntry e in z.Entries) {
          if (e.FullName.EndsWith("/") || e.FullName.EndsWith("\\")) continue;
          string rel = e.FullName.Replace('/', '\\');
          string dest = Path.GetFullPath(Path.Combine(target, rel));
          if (!dest.StartsWith(target + "\\")) continue;
          string low = rel.ToLowerInvariant();
          if (File.Exists(dest) && (low == "game\\options.txt" || low.StartsWith("game\\saves\\"))) continue;
          Directory.CreateDirectory(Path.GetDirectoryName(dest));
          e.ExtractToFile(dest, true);
        }
      }
      File.WriteAllText(marker, build);
    }

    ProcessStartInfo psi = new ProcessStartInfo(Path.Combine(target, "OfflineMC.exe"));
    psi.WorkingDirectory = target;
    psi.UseShellExecute = false;
    using (Process p = Process.Start(psi)) { p.WaitForExit(); return p.ExitCode; }
  }
}
'@
[IO.File]::WriteAllText($cs, $code.Replace("__BUILD__", $build))

& $csc /nologo /target:exe "/out:$out" /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll "/resource:$zip,payload.zip" $cs
if ($LASTEXITCODE -eq 0) { Write-Host "Done: $out" } else { Write-Host "Compile failed" -ForegroundColor Red }