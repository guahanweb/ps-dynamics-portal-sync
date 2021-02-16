Param(
  [Parameter(Mandatory=$False)]
  [String]
  $ConnectionString,
  [Parameter(Mandatory=$False)]
  [Boolean]
  $Import,
  [Parameter(Mandatory=$False)]
  [String]
  $BasePath
)

# install Xrm module if not installed
$XrmName = "Microsoft.Xrm.Tooling.CrmConnector.PowerShell";
if (Get-Module -ListAvailable -Name $XrmName) {
} else {
  Write-Output "-- Installing Dynamics Xrm Module --"
  Install-Module -Name $XrmName;
}

# import local modules
Import-Module -Name .\lib\helpers.psm1 -Force;
Import-Module -Name .\lib\portal.psm1 -Force;

# See if we've been provided a connection string
if (-not($ConnectionString)) {
  $CrmClient = Get-CrmConnection -InteractiveMode;
} else {
  $CrmClient = Get-CrmConnection -ConnectionString $ConnectionString;
}

# Default base path
if (-not($BasePath)) {
  $BasePath = '.';
}

function ProcessWebsites {
  Param(
    [Parameter(Mandatory=$True)]
    $CrmClient,
    [Parameter(Mandatory=$True)]
    [String]
    $BaseDir,
    [Parameter(Mandatory=$True)]
    [Array]
    $Websites,
    [Parameter(Mandatory=$True)]
    [Array]
    $PortalLanguages,
    [Parameter(Mandatory=$True)]
    [Array]
    $Languages,
    [Parameter(Mandatory=$False)]
    [Boolean]
    $Import
  )

  $updateCount = 0;
  # Start Creating Folder Structure
  foreach ($website in $Websites) {
    Write-Output "-- Start Creating Folder Structure for $($website.Name) --";
    $validName = ReplaceInvalidChars -Filename $website.Name;
    $siteFolder = CreateFolder -Path $BaseDir -Folder $validName;

    # Web Files
    Write-Output "-- Start Loading WebFiles --";
    $webfiles = Get-PortalWebFiles -CrmClient $CrmClient -WebsiteId $website.WebsiteId;
    $dirInfoWebFiles = CreateFolder -Path $siteFolder.FullName -Folder 'WebFiles';

    foreach ($webfile in $webfiles) {
      [String]$s = $webfile.Filename;
      $idx = $s.LastIndexOf('.');

      $filenamePart1 = '';
      $filenamePart2 = '';

      if ($idx -ne -1) {
        $filenamePart1 = $s.Substring(0, $idx);
        $filenamePart2 = $s.Substring($idx + 1);

        $webFilePath = Join-Path -Path $dirInfoWebFiles.FullName -ChildPath "$filenamePart1-$($webfile.AnnotationId).$filenamePart2";
        if (-not($Import)) {
          # pull down dynamics latest
          [io.file]::WriteAllBytes($webFilePath, [Convert]::FromBase64String($webfile.DocumentBody));
        } else {
          # patch dynamics with local changes
          if ([io.file]::Exists($webFilePath)) {
            $webFileDisk = [io.file]::ReadAllBytes($webFilePath);
            if ($webFileDisk.Length -gt 0) {
              $webFileOnline = [Convert]::FromBase64String($webFile.DocumentBody);

              if (-not(CompareByteArray -a1 $webFileDisk -a2 $webFileOnline)) {
                # local changes found
                Write-Output "Changes detected in WebFile: $($webFile.Filename)";

                $documentbody = [Convert]::ToBase64String($webFileDisk);
                $Payload = @{
                  documentbody = $documentbody
                  mimetype = $webFile.MimeType
                } | ConvertTo-Json;

                $webfileuri = "annotations($($webFile.AnnotationId))";
                Update-PortalData -CrmClient $CrmClient -Path $webfileuri -Payload $Payload;
                $updateCount++;
              }
            }
          }
        }
      }
    }

    # Web Pages (Content and Custom CSS/JS)
    Write-Output "-- Start Loading WebPages --";
    $webpages = Get-PortalWebPages -CrmClient $CrmClient -WebsiteId $website.WebsiteId;
    $dirInfoWebPages = CreateFolder -Path $siteFolder.FullName -Folder 'WebPages';

    foreach ($page in $webpages) {
      $validName = ReplaceInvalidChars -Filename $page.Name;
      $currentPath = CreateFolder -Path $dirInfoWebPages.FullName -Folder $validName;

      $pathContent = Join-Path -Path $currentPath.FullName -ChildPath "$($page.Name)-Content-$($page.WebPageId).html";
      $pathCss = Join-Path -Path $currentPath.FullName -ChildPath "$($page.Name)-CustomCss-$($page.WebPageId).css";
      $pathJavaScript = Join-Path -Path $currentPath.FullName -ChildPath "$($page.Name)-CustomJavaScript-$($page.WebPageId).js";

      if (-not($Import)) {
        if ($page.Copy.Length -gt 0) {
          [io.file]::WriteAllText($pathContent, $page.Copy);
        }

        if ($page.CustomCss.Length -gt 0) {
          [io.file]::WriteAllText($pathCss, $page.CustomCss);
        }

        if ($page.CustomJavaScript.Length -gt 0) {
          [io.file]::WriteAllText($pathJavaScript, $page.CustomJavaScript);
        }
      } else {
        # Check Content updates
        $content = [String]::Empty;
        if (Test-Path -Path $pathContent -PathType Leaf) {
          $content = [io.file]::ReadAllText($pathContent);
          if (-not($page.Copy -eq $content)) {
            Write-Output "Changes detected in page content: $($page.Name)";

            # Update content
            $Payload = @{
              adx_copy = $content
            } | ConvertTo-Json;

            $webpageuri = "adx_webpages($($page.WebPageId))";
            Update-PortalData -CrmClient $CrmClient -Path $webpageuri -Payload $Payload;
            $updateCount++;
          }
        }

        # Check CSS updates
        $css = [String]::Empty;
        if (Test-Path -Path $pathCss -PathType Leaf) {
          $css = [io.file]::ReadAllText($pathCss);

          if (-not($page.CustomCss -eq $css)) {
            Write-Output "Changes detected in page custom CSS: $($page.Name)";

            # Update CSS
            $Payload = @{
              adx_customcss = $css
            } | ConvertTo-Json;

            $webpageuri = "adx_webpages($($page.WebPageId))";
            Update-PortalData -CrmClient $CrmClient -Path $webpageuri -Payload $Payload;
            $updateCount++;
          }
        }

        # Check JavaScript updates
        $javascript = [String]::Empty;
        if (Test-Path -Path $pathJavaScript -PathType Leaf) {
          $javascript = [io.file]::ReadAllText($pathJavaScript);
          if (-not($page.CustomJavaScript -eq $javascript)) {
            Write-Output "Changes detected in page custom JavaScript: $($page.Name)";

            # Update JavaScript
            $Payload = @{
              adx_customjavascript = $javascript
            } | ConvertTo-Json;

            $webpageuri = "adx_webpages($($page.WebPageId))";
            Update-PortalData -CrmClient $CrmClient -Path $webpageuri -Payload $Payload;
            $updateCount++;
          }
        }
      }
    }

    # Templates (liquid)
    Write-Output "-- Start Loading Templates --";
    $templates = Get-PortalTemplates -CrmClient $CrmClient -WebsiteId $website.WebsiteId;
    $dirInfoTemplates = CreateFolder -Path $siteFolder.FullName -Folder 'WebTemplates';

    foreach ($template in $templates) {
      $validName = ReplaceInvalidChars -Filename $template.Name;
      $currentPath = CreateFolder -Path $dirInfoTemplates.FullName -Folder $validName;

      $pathContent = Join-Path -Path $currentPath.FullName -ChildPath "$validName-$($template.WebTemplateId).html";

      if (-not($Import)) {
        if ($template.Source.Length -gt 0) {
          [io.file]::WriteAllText($pathContent, $template.Source);
        }
      } else{
        # Update template with any changes
        $content = [String]::Empty;
        if (Test-Path -Path $pathContent -PathType Leaf) {
          $content = [io.file]::ReadAllText($pathContent);
          if (-not($template.Source -eq $content)) {
            Write-Output "Changes detected in content: $($template.Name)";

            $Payload = @{
              adx_source = $content
            } | ConvertTo-Json;

            $webpageuri = "adx_webtemplates($($template.WebTemplateId))";
            Update-PortalData -CrmClient $CrmClient -Path $webpageuri -Payload $Payload;
            $updateCount++;
          }
        }
      }
    }

    # Content Snippets
    Write-Output "-- Start Loading ContentSnippets --";
    $snippets = Get-PortalContentSnippets -CrmClient $CrmClient -WebsiteId $website.WebsiteId;
    $dirInfoContentSnippets = CreateFolder -Path $siteFolder.FullName -Folder 'ContentSnippets';

    foreach ($snippet in $snippets) {
      $validName = ReplaceInvalidChars -Filename $snippet.Name;
      $currentPath = CreateFolder -Path $dirInfoContentSnippets.FullName -Folder $validName;

      $lang = $Languages | ForEach-Object { $Record = $Null } { if ($Null -eq $Record -and $_.WebSiteLanguageId -eq $snippet.ContentSnippetLanguageId) { $Record = $_; } } { $Record };
      if ($Null -ne $lang) {
        $portalLang = $PortalLanguages | ForEach-Object { $Record = $Null } { if ($Null -eq $Record -and $_.PortalLanguageId -eq $lang.PortalLanguageId) { $Record = $_; } } { $Record };
        if ($Null -ne $portalLang) {
          $currentPath = CreateFolder -Path $currentPath.FullName -Folder $portalLang.LanguageCode;
        }
      }

      $pathContent = Join-Path -Path $currentPath.FullName -ChildPath "$validName-$($snippet.ContentSnippetId).html";

      if (-not($Import)) {
        if ($snippet.Value.Length -gt 0) {
          [io.file]::WriteAllText($pathContent, $snippet.Value);
        }
      } else {
        # Update content snippets
        $content = [String]::Empty;
        if (Test-Path -Path $pathContent -PathType Leaf) {
          $content = [io.file]::ReadAllText($pathContent);
          if (-not($snippet.Value -eq $content)) {
            Write-Output "Changes detected in content snippet: $($snippet.Name)";

            $Payload = @{
              adx_value = $content
            } | ConvertTo-Json;

            $webpageuri = "adx_contentsnippets($($snippet.ContentSnippetId))";
            Update-PortalData -CrmClient $CrmClient -Path $webpageuri -Payload $Payload;
            $updateCount++;
          }
        }
      }
    }
  }

  if ($Import) {
    Write-Output "-- Total Files Updated: $updateCount --";
  } else {
    Write-Output "-- Finished Downloading Files -- ";
  }
}

$languages  = Get-PortalLanguages -CrmClient $CrmClient
$websites = Get-PortalWebsites -CrmClient $CrmClient;
$wLanguages = Get-PortalWebsiteLanguages -CrmClient $CrmClient;

ProcessWebsites -Import $Import -CrmClient $CrmClient -BaseDir .\sites -Websites $websites -Languages $languages -PortalLanguages $wLanguages -BaseDir $BasePath

# Close the connection to CRM
$CrmClient.Dispose();