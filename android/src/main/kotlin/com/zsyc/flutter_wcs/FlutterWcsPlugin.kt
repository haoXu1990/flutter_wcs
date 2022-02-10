package com.zsyc.flutter_wcs

import android.os.Message
import android.util.Log
import androidx.annotation.NonNull
import com.chinanetcenter.wcs.android.ClientConfig
import com.chinanetcenter.wcs.android.api.FileUploader
import com.chinanetcenter.wcs.android.api.ParamsConf
import com.chinanetcenter.wcs.android.entity.OperationMessage
import com.chinanetcenter.wcs.android.internal.UploadFileRequest
import com.chinanetcenter.wcs.android.listener.FileUploaderListener
import com.zsyc.flutter_wcs.util.CommonUtil
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONObject

/** FlutterWcsPlugin */
class FlutterWcsPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_wcs")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "getPlatformVersion") {
      result.success("Android ${android.os.Build.VERSION.RELEASE}")
    } else if (call.method == "initSDK") {
      initSDK(call, result)
    } else {
      result.notImplemented()
    }
  }

  /**
   *  初始化方法
   *  @param MethodCall 中传入 uploadDomain 上传的域名
   * */
  private fun initSDK(call: MethodCall, result: Result) {
    val uploadDomainURL = CommonUtil.getParam<String>(call, result, "uploadDomain")

    FileUploader.setUploadUrl(uploadDomainURL)
    val config = ClientConfig()
    config.maxConcurrentRequest = 10
    FileUploader.setClientConfig(config)
    result.success(true)
  }

  private fun normalUpload(call: MethodCall, result: Result) {


    val token = CommonUtil.getParam<String>(call, result, "token")
    val fileURL = CommonUtil.getParam<String>(call, result, "fileURL")
    val fileName = CommonUtil.getParam<String>(call, result, "fileName")
    val key = CommonUtil.getParam<String>(call, result, "key")


    val conf = ParamsConf()
    conf.fileName = fileName
    conf.keyName = key

    FileUploader.upload(this, token, fileURL, null, object : FileUploaderListener() {
      override fun onSuccess(p0: Int, p1: JSONObject?) {
        result.success(true)
      }

      override fun onFailure(p0: OperationMessage?) {
        result.error("10001", "出错啦", "上传文件出错")
      }

      override fun onProgress(request: UploadFileRequest?, currentSize: Long, totalSize: Long) {

      }
    })
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}