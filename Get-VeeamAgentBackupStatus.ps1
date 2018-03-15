$buEvents = Get-EventLog -Logname "Veeam Agent" -InstanceID 190,191 -After (Get-Date).AddDays(-1)

switch ($buEvents[0].InstanceID) {
    190 {$buStatus = 0}
    191 {$buStatus = 2}
    default {$buStatus = 1}
}

$buEventTime = $buEvents[0].TimeGenerated