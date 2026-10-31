package com.agy.shell;

import android.content.Context;

import java.io.File;

/** Locates the su (super-user) binary on the system. */
public final class SuLocator {

    private final Context appContext;

    public SuLocator(Context context) {
        this.appContext = context.getApplicationContext();
    }

    /**
     * Finds the first existing and executable su binary across known root paths
     * (Magisk, KernelSU, APatch, system xbin/bin).
     */
    public File suBinary() {
        File[] candidates = new File[]{
                new File("/system/bin/su"),
                new File("/system/xbin/su"),
                new File("/sbin/su"),
                new File("/data/adb/ksu/bin/su"),
                new File("/data/adb/ap/bin/su"),
                new File("/data/adb/magisk/su")
        };
        for (File candidate : candidates) {
            if (candidate.exists()) {
                return candidate;
            }
        }
        // Fallback: system default name for PATH resolution
        return new File("/system/bin/su");
    }
}
