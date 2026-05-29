param(
  [string]$OutputDirectory = "assets/models/style_transfer"
)

$ErrorActionPreference = "Stop"

$models = @(
  @{
    Name = "style_prediction_int8.tflite"
    Url = "https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite"
    ExpectedBytes = 2828838
  },
  @{
    Name = "style_transfer_int8.tflite"
    Url = "https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite"
    ExpectedBytes = 284398
  }
)

Write-Host "Mixelith local style-transfer model download"
Write-Host "These model files are for local evaluation only."
Write-Host "They are ignored by Git and must not be committed until redistribution terms are confirmed."
Write-Host ""

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

foreach ($model in $models) {
  $target = Join-Path $OutputDirectory $model.Name
  Write-Host "Downloading $($model.Name)..."
  Invoke-WebRequest -Uri $model.Url -OutFile $target

  $actualBytes = (Get-Item $target).Length
  if ($actualBytes -ne $model.ExpectedBytes) {
    throw "Unexpected size for $($model.Name): expected $($model.ExpectedBytes), got $actualBytes."
  }

  Write-Host "Saved $target ($actualBytes bytes)"
}

Write-Host ""
Write-Host "Done. Do not commit the downloaded .tflite files."
