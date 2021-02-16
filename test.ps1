$mylist = @(
  @{ foo = "bar" },
  @{ foo = "fizz" },
  @{ foo = "buzz" },
  @{ foo = "xxx" },
  @{ foo = "yyy" }
);

$firstOrNull = $mylist | ForEach-Object { $Record = $Null } { if ($Record -eq $Null -and $_.foo -eq 'aaa') { $Record = $_; } } { $Record }
Write-Output "Result: $firstOrNull";
