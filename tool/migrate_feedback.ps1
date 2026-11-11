$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$libraryRoot = Join-Path $projectRoot 'lib'
$utf8 = New-Object System.Text.UTF8Encoding($false)
Get-ChildItem -LiteralPath $libraryRoot -Recurse -Filter '*.dart' | ForEach-Object {
  if ($_.Name -eq 'app_snackbar.dart') { return }
  $source = [IO.File]::ReadAllText($_.FullName)
  $updated = [regex]::Replace($source, 'ScaffoldMessenger\.of\((\w+)\)\.showSnackBar\(', 'AppSnackbar.showSnackBar($1, ')
  $updated = [regex]::Replace($updated, '\bmessenger\.showSnackBar\(', 'AppSnackbar.showSnackBar(context, ')
  if ($updated -ne $source) {
    if ($updated -notmatch "import '[^']*app_snackbar.dart'") {
      $updated = "import 'package:food_fight/core/utils/app_snackbar.dart';`n" + $updated
    }
    if ($updated -notmatch '\bmessenger\.') {
      $updated = [regex]::Replace($updated, '(?m)^\s*final messenger = ScaffoldMessenger\.of\(\w+\);\r?\n', '')
    }
    [IO.File]::WriteAllText($_.FullName, $updated, $utf8)
  }
}
