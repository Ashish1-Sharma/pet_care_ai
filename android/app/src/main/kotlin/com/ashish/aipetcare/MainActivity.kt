package com.ashish.aipetcare

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Use the modern WindowCompat API instead of the deprecated
        // View.SYSTEM_UI_FLAG_* / window.setStatusBarColor() path.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
