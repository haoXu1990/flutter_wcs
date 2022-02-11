package com.zsyc.flutter_wcs.util

import com.alibaba.fastjson.JSON
import com.alibaba.fastjson.serializer.ValueFilter

public object JsonUtil {
    fun toJsonString(data: Any) : String {
        if (data is String) return data.toString()
        return JSON.toJSONString(data)
    }
}

