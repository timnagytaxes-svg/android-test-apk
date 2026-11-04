package com.gangalangus.testapk;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(32, 32, 32, 32);
        root.setBackgroundColor(Color.rgb(18, 24, 38));
        TextView title = new TextView(this);
        title.setText("GANGALANGUS APK TEST");
        title.setTextColor(Color.WHITE);
        title.setTextSize(25);
        title.setGravity(Gravity.CENTER);
        Button button = new Button(this);
        button.setText("TEST BUTTON");
        button.setOnClickListener(v -> title.setText("IT WORKS! 🎉"));
        root.addView(title);
        root.addView(button);
        setContentView(root);
    }
}
