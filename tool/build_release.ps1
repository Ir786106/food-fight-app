param(
    [ValidateSet('Android', 'Windows')] [string]$Target = 'Android',
    [string]$InnoCompiler,
    [switch]$AppBundle
)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $version = Select-String -Path pubspec.yaml -Pattern '^version: (\d+\.\d+\.\d+)\+([1-9]\d*)$'
    if (!$version) { throw 'Missing release version in pubspec.yaml.' }
    $name = $version.Matches[0].Groups[1].Value
    $build = $version.Matches[0].Groups[2].Value
    if ($Target -eq 'Android') {
        if (!(Test-Path -LiteralPath 'android/key.properties') -or
            !(Test-Path -LiteralPath 'android/app/google-services.json')) {
            throw 'Android signing or Firebase configuration is missing.'
        }
        flutter build apk --release --target-platform android-arm,android-arm64 --build-name $name --build-number $build
        if ($LASTEXITCODE -ne 0) { throw 'Android APK build failed.' }
        $output = 'build/release-candidate'
        New-Item -ItemType Directory -Force -Path $output | Out-Null
        $apk = Join-Path $output "FoodFight_v${name}_release.apk"
        Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination $apk
        $digest = (Get-FileHash -Algorithm SHA256 -LiteralPath $apk).Hash.ToLowerInvariant()
        "$digest  $(Split-Path -Leaf $apk)" | Set-Content -Encoding ascii -LiteralPath "$apk.sha256"
        if ($AppBundle) {
            flutter build appbundle --release --build-name $name --build-number $build
            if ($LASTEXITCODE -ne 0) { throw 'Android App Bundle build failed.' }
        }
    } else {
        flutter build windows --release --build-name $name --build-number $build
        if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
        if (!$InnoCompiler) {
            $InnoCompiler = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'
        }
        if (!(Test-Path -LiteralPath $InnoCompiler)) {
            throw 'Windows bundle built. Pass -InnoCompiler with the Inno Setup 6 executable to package it.'
        }
        $bundle = (Resolve-Path -LiteralPath 'build/windows/x64/runner/Release').Path
        $output = Join-Path (Get-Location) 'build/release-candidate'
        New-Item -ItemType Directory -Force -Path $output | Out-Null
        & $InnoCompiler "/DAppVersion=$name" "/DAppBuild=$build" "/DBundleDir=$bundle" "/O$output" 'windows/installer.iss'
        if ($LASTEXITCODE -ne 0) { throw 'Windows installer packaging failed.' }
    }
} finally {
    Pop-Location
}
