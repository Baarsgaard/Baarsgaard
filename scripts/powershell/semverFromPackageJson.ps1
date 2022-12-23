$BUILD = (Get-Content package.json) -join "`n" | ConvertFrom-Json | Select -ExpandProperty "version"

Write-Host "##teamcity[setParameter name='env.BUILD' value='$BUILD']"
