package com.mixelith

import android.content.Intent
import com.mixelith.onnx.OnnxModelImportBridge
import com.mixelith.onnx.OnnxStyleTransferBridge
import com.mixelith.picker.BatchImagePickerBridge
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var onnxModelImportBridge: OnnxModelImportBridge? = null
    private var batchImagePickerBridge: BatchImagePickerBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OnnxStyleTransferBridge.channelName,
        ).setMethodCallHandler(OnnxStyleTransferBridge(applicationContext))
        val importBridge = OnnxModelImportBridge(this, applicationContext)
        onnxModelImportBridge = importBridge
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OnnxModelImportBridge.channelName,
        ).setMethodCallHandler(importBridge)
        val pickerBridge = BatchImagePickerBridge(this, applicationContext)
        batchImagePickerBridge = pickerBridge
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BatchImagePickerBridge.channelName,
        ).setMethodCallHandler(pickerBridge)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (onnxModelImportBridge?.handleActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        if (batchImagePickerBridge?.handleActivityResult(requestCode, resultCode, data) == true) {
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
