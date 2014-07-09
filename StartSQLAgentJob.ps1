function Start-SQLAgentJob
{
	param
	(
		[parameter(Mandatory=$false)]
		[String]
		$JobName = "FIM_TemporalEventsJob",
		[parameter(Mandatory=$true)]
		[String]
		$SQLServer,	
		[parameter(Mandatory=$false)]
		[Switch]
		$Wait
	)
	
	$connection = New-Object System.Data.SQLClient.SQLConnection
	$Connection.ConnectionString = "server={0};database=FIMService;trusted_connection=true;" -f $SQLServer
	$connection.Open()
	
	$cmd = New-Object System.Data.SQLClient.SQLCommand
	$cmd.Connection = $connection
	$cmd.CommandText = "exec msdb.dbo.sp_start_job '{0}'" -f $JobName
	
	Write-Verbose "Executing job $JobName on $SQLServer"
	$cmd.ExecuteNonQuery()
	
	if ($Wait)
	{
		$cmd.CommandText = "exec msdb.dbo.sp_help_job @job_name='{0}', @execution_status = 4" -f $JobName
		
		$reader = $cmd.ExecuteReader()
		
		while ($reader.HasRows -eq $false)
		{
			Write-Verbose "Job is still executing. Sleeping..."
			Start-Sleep -Milliseconds 1000
			
			$reader.Close()
			$reader = $cmd.ExecuteReader()
		}
	}
	$connection.Close()
}

