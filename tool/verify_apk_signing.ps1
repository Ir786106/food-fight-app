param(
    [Parameter(Mandatory)] [string]$OldApk,
    [Parameter(Mandatory)] [string]$NewApk,
    [Parameter(Mandatory)] [string]$ApkSigner
)
$ErrorActionPreference = 'Stop'
$signer = (Resolve-Path -LiteralPath $ApkSigner).Path

function Get-ApkCertificates([string]$ApkPath) {
    $apk = (Resolve-Path -LiteralPath $ApkPath).Path
    $lines = & $signer verify --print-certs $apk
    if ($LASTEXITCODE -ne 0) { throw "APK signature verification failed for $apk." }
    $fingerprints = @($lines | Select-String '^Signer #\d+ certificate SHA-256 digest: ([A-Fa-f0-9]{64})$' |
        ForEach-Object { $_.Matches[0].Groups[1].Value.ToLowerInvariant() } | Sort-Object -Unique)
    if (!$fingerprints.Count) { throw "No verified signing certificate found in $apk." }
    return $fingerprints
}

$old = @(Get-ApkCertificates $OldApk)
$new = @(Get-ApkCertificates $NewApk)
if (Compare-Object -ReferenceObject $old -DifferenceObject $new) {
    throw 'APK signing certificates differ. An in-place update cannot use this candidate.'
}
Write-Output 'Verified: both APKs have the same signing certificate fingerprints.'
