function CreateFolder {
  Param(
    [Parameter(Mandatory=$True)]
    [String]
    $Path,
    [Parameter(Mandatory=$True)]
    [String]
    $Folder
  )

  $path = Join-Path -Path $Path.Trim() -ChildPath $Folder.Trim();
  New-Item -ItemType directory $path -Force;
  return $path;
}

function ReplaceInvalidChars {
  Param(
    [Parameter(Mandatory=$True)]
    [String]
    $Filename
  )

  if ([String]::IsNullOrEmpty($Filename)) {
    Write-Error "Filename cannot be null or empty";
  }

  return [String]::Join('_', $Filename.Split([system.io.path]::GetInvalidFileNameChars())).Trim();
}

function CompareByteArray {
  Param(
    [Parameter(Mandatory=$True)]
    [System.Byte[]]
    $a1,
    [Parameter(Mandatory=$True)]
    [System.Byte[]]
    $a2
  );

  return [system.linq.enumerable]::SequenceEqual($a1, $a2);
}
