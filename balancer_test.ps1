$server1Count = 0
$server2Count = 0
$totalRequests = 20

1..$totalRequests | ForEach-Object { 
    $id = $_
    try {
        $response = Invoke-WebRequest -Uri "http://192.168.31.41:8080/?request=$id" -ErrorAction Stop
        
        # Определяем, какой сервер ответил
        if ($response.Content -match '<a href="server1\.txt">') {
            $server1Count++
            Write-Host "Request $id => SERVER1" -ForegroundColor Green
        }
        elseif ($response.Content -match '<a href="server2\.txt">') {
            $server2Count++
            Write-Host "Request $id => SERVER2" -ForegroundColor Blue
        }
        else {
            Write-Host "Request $id => UNKNOWN SERVER" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Request $id => FAILED: $_" -ForegroundColor Red
    }
}

# Рассчитываем процентное соотношение
$server1Percent = ($server1Count / $totalRequests) * 100
$server2Percent = ($server2Count / $totalRequests) * 100

# Выводим статистику
Write-Host "`n=== Load Distribution Statistics ===" -ForegroundColor Cyan
Write-Host "SERVER1 requests: $server1Count ($([math]::Round($server1Percent, 1))%)"
Write-Host "SERVER2 requests: $server2Count ($([math]::Round($server2Percent, 1))%)"
Write-Host "Total requests: $totalRequests"
