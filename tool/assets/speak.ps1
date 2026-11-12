# Genera las narraciones PROVISIONALES con las voces SAPI instaladas en Windows.
# Uso: pwsh tool/assets/speak.ps1 -OutDir <carpeta>
# Salida: intro_es.wav e intro_en.wav (luego tool/assets/build_assets.py las pasa a MP3).
param([Parameter(Mandatory = $true)][string]$OutDir)

Add-Type -AssemblyName System.Speech

function Speak([string]$Voice, [string]$Text, [string]$File) {
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SelectVoice($Voice)
    $synth.Rate = -2
    $format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(44100, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
    $synth.SetOutputToWaveFile($File, $format)
    $synth.Speak($Text)
    $synth.Dispose()
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
Speak 'Microsoft Helena Desktop' 'El bosque nuboso. En este bosque, las nubes pasan entre los árboles. ¿Ves la rana entre las hojas?' (Join-Path $OutDir 'intro_es.wav')
Speak 'Microsoft Zira Desktop' 'The Cloud Forest. In this forest, clouds drift between the trees. Can you spot the frog among the leaves?' (Join-Path $OutDir 'intro_en.wav')
Get-ChildItem $OutDir -Filter *.wav | Select-Object Name, Length
