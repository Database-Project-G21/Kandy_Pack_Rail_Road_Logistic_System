$ErrorActionPreference = 'Stop'

# Read credentials locally without displaying them or putting them in command arguments.
$settings = @{}
Get-Content -LiteralPath (Join-Path $PSScriptRoot '../kandypackbackend/.env') | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)=(.*)$') { $settings[$matches[1]] = $matches[2] }
}
foreach ($key in @('SPRING_DATASOURCE_URL', 'SPRING_DATASOURCE_USERNAME', 'SPRING_DATASOURCE_PASSWORD')) {
    if (-not $settings[$key]) { throw "Missing $key in backend .env" }
}
$jdbcUrl = $settings['SPRING_DATASOURCE_URL']
if (-not $jdbcUrl.StartsWith('jdbc:postgresql://')) { throw 'Expected a PostgreSQL JDBC URL' }
$connection = [uri]$jdbcUrl.Substring(5)
if (-not $connection.Host.EndsWith('.neon.tech')) { throw 'Expected a Neon database host' }
$connectionEnvironment = @{
    PGHOST = $connection.Host
    PGPORT = '5432'
    PGDATABASE = [uri]::UnescapeDataString($connection.AbsolutePath.TrimStart('/'))
    PGUSER = $settings['SPRING_DATASOURCE_USERNAME']
    PGPASSWORD = $settings['SPRING_DATASOURCE_PASSWORD']
    PGSSLMODE = 'require'
    PGCHANNELBINDING = 'require'
}
$previousEnvironment = @{}
$dockerArguments = @('run', '--rm')
try {
    foreach ($key in $connectionEnvironment.Keys) {
        $previousEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
        [Environment]::SetEnvironmentVariable($key, $connectionEnvironment[$key], 'Process')
        $dockerArguments += @('--env', $key)
    }
    $count = & docker @dockerArguments postgres:18-alpine psql -X -A -t -v ON_ERROR_STOP=1 -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'"
    if ($LASTEXITCODE -ne 0) { throw 'Could not check the Neon database. No migration was run.' }
    if ([int](($count -join '').Trim()) -ne 0) {
        throw 'The Neon public schema already contains tables. This baseline requires an empty database. No migration was run.'
    }
    $migrationPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'migrations')).Path
    & docker @dockerArguments --mount "type=bind,source=$migrationPath,target=/migrations,readonly" postgres:18-alpine psql -X -f /migrations/run_all.psql
    if ($LASTEXITCODE -ne 0) { throw 'Migration failed; the runner transaction was rolled back. Review the error above.' }
    Write-Output 'Neon migration completed successfully.'
} finally {
    foreach ($key in $previousEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($key, $previousEnvironment[$key], 'Process')
    }
}
