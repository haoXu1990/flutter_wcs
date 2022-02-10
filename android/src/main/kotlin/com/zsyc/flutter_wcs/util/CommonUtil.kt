package com.zsyc.flutter_wcs.util

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


public object CommonUtil {

    private val MAIN_HANDLER: Handler = Handler(Looper.getMainLooper())

    fun <T> getParam(methodCall: MethodCall, result: MethodChannel.Result, param: String): T {
        val par: T? = methodCall.argument(param)

        if (par == null) {
            result.error(
                "Missing parameter",
                "Cannot find parameter `$param` or `$param` is null!",
                5
            )
            throw RuntimeException("Cannot find parameter `$param` or `$param` is null!")
        }
        return par
    }

    fun runMainThreadReturn(result: MethodChannel.Result, param: Any?) {
        MAIN_HANDLER.post(Runnable { result.success(param) })
    }

    fun runMainThreadReturnError(
        result: MethodChannel.Result,
        errorCode: String?,
        errorMessage: String?,
        errorDetails: Any?
    ) {
        MAIN_HANDLER.post(Runnable { result.error(errorCode, errorMessage, errorDetails) })
    }

    fun runMainThreadMethod(runnable: Runnable) {
        MAIN_HANDLER.post(runnable)
    }
}