Get-ChildItem -Path '..\lib\erp' -Filter '*.dart' -Recurse | ForEach-Object {
    $f = $_.FullName
    $c = Get-Content $f
    $newC = $c -replace 'withValues\(alpha: (0\.\d+)\)', 'withOpacity($1)'
    if ($c -ne $newC) {
        $newC | Set-Content $f
        Write-Host "Fixed: $f"
    }
}
