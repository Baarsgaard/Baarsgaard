$url = 'url'
$user = 'username'
$pass = 'password'
pks login -a $url -u $user -p $pass -k
echo $pass | pks get-credentials arrigocluster
#Start-Process powershell -Verb runAs -ArgumentList 'kubectl proxy'


$input_path = $HOME + '\.kube\config'
$regex = '[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*$'
$content = Select-String -Pattern $regex -Path $input_path -List | Select-Object -First 1
Set-Clipboard -Value $content.Matches
Write-Host 'Token copied to clipboard'


Write-Host 'Opening browser'
[Diagnostics.Process]::Start(‘http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login‘)
kubectl proxy