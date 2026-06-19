package com.mixelith.onnx

import java.nio.FloatBuffer
import kotlin.test.Test
import kotlin.test.assertEquals

class OnnxTensorImageCodecTest {
    @Test
    fun postprocessPixelsPreservesNonSquareNchwCornerOrder() {
        val width = 3
        val height = 2
        val channelSize = width * height
        val values = FloatArray(channelSize * 3)

        fun setPixel(index: Int, red: Float, green: Float, blue: Float) {
            values[index] = red
            values[channelSize + index] = green
            values[channelSize * 2 + index] = blue
        }

        setPixel(0, 255f, 0f, 0f)
        setPixel(2, 0f, 255f, 0f)
        setPixel(3, 0f, 0f, 255f)
        setPixel(5, 255f, 255f, 0f)

        val pixels = OnnxTensorImageCodec.postprocessPixels(
            FloatBuffer.wrap(values),
            width,
            height,
        )

        assertEquals(0xffff0000.toInt(), pixels[0])
        assertEquals(0xff00ff00.toInt(), pixels[2])
        assertEquals(0xff0000ff.toInt(), pixels[3])
        assertEquals(0xffffff00.toInt(), pixels[5])
    }

    @Test
    fun preprocessPixelsPreservesNonSquareNchwCornerOrder() {
        val width = 3
        val height = 2
        val pixels = IntArray(width * height)
        pixels[0] = 0xffff0000.toInt()
        pixels[2] = 0xff00ff00.toInt()
        pixels[3] = 0xff0000ff.toInt()
        pixels[5] = 0xffffff00.toInt()

        val buffer = OnnxTensorImageCodec.preprocessPixels(pixels, width, height)
        val values = FloatArray(width * height * 3)
        buffer.get(values)

        assertEquals(255f, values[0])
        assertEquals(0f, values[2])
        assertEquals(0f, values[3])
        assertEquals(255f, values[5])

        val greenOffset = width * height
        assertEquals(0f, values[greenOffset])
        assertEquals(255f, values[greenOffset + 2])
        assertEquals(0f, values[greenOffset + 3])
        assertEquals(255f, values[greenOffset + 5])

        val blueOffset = width * height * 2
        assertEquals(0f, values[blueOffset])
        assertEquals(0f, values[blueOffset + 2])
        assertEquals(255f, values[blueOffset + 3])
        assertEquals(0f, values[blueOffset + 5])
    }
}
