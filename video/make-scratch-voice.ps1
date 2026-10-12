$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech
$film = Get-Content (Join-Path $PSScriptRoot 'src/content.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$folder = Join-Path $PSScriptRoot 'public/audio'
New-Item -ItemType Directory -Force $folder | Out-Null
$voice = New-Object System.Speech.Synthesis.SpeechSynthesizer
$voice.SelectVoice('Microsoft Zira Desktop')
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(24000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
$report = @()
try {
  for ($i = 0; $i -lt $film.cues.Count; $i++) {
    $cue = $film.cues[$i]
    $path = Join-Path $folder ('vo-{0:D2}.wav' -f ($i + 1))
    $maxSeconds = $cue.end - $cue.start - 0.08
    $seconds = 999
    for ($rate = 1; $rate -le 6; $rate++) {
      $voice.Rate = $rate
      $voice.SetOutputToWaveFile($path, $format)
      $voice.Speak($cue.text)
      $voice.SetOutputToNull()
      $seconds = ((Get-Item $path).Length - 46) / 48000.0
      if ($seconds -le $maxSeconds) { break }
    }
    if ($seconds -gt $maxSeconds) { throw "Voice cue $($i + 1) exceeds its slot." }
    $report += [pscustomobject]@{cue=$i+1; duration=$seconds; available=$maxSeconds; rate=$rate; voice='Microsoft Zira Desktop (temporary)'}
  }
} finally { $voice.Dispose() }
$report | ConvertTo-Json | Set-Content (Join-Path $PSScriptRoot 'out/voice-timing.json') -Encoding UTF8
Write-Host "Created $($report.Count) temporary English voice clips."
