package com.agy.shell;

import android.content.Context;
import android.util.Log;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.util.Map;

/**
 * Superuser root execution bridge.
 * Executes commands with root privileges (uid=0) via the system `su` binary,
 * following libsu / KernelSU patterns (e.g., mount namespace options and clean environments).
 */
public final class SuBridge {

    private static final String TAG = "SuBridge";

    private final Context appContext;
    private final SuLocator locator;
    private volatile Boolean rootAvailableCache = null;

    public SuBridge(Context context) {
        this.appContext = context.getApplicationContext();
        this.locator = new SuLocator(context);
    }

    /**
     * Checks if `su` is present on the filesystem.
     */
    public boolean isAvailable() {
        File su = locator.suBinary();
        return su.exists() && su.canExecute();
    }

    /**
     * Actively checks if root permission is granted (uid=0).
     */
    public synchronized boolean hasRootAccess() {
        if (rootAvailableCache != null) {
            return rootAvailableCache;
        }
        if (!isAvailable()) {
            rootAvailableCache = false;
            return false;
        }
        try {
            String out = exec("id -u");
            boolean ok = "0".equals(out.trim());
            rootAvailableCache = ok;
            return ok;
        } catch (Throwable t) {
            Log.w(TAG, "Root access check failed: " + t.getMessage());
            rootAvailableCache = false;
            return false;
        }
    }

    /**
     * Runs `cmd` as root.
     * Uses `--mount-master` when available to access the global mount namespace
     * (KernelSU / Magisk App Profile compatibility).
     */
    public String exec(String cmd) {
        return exec(cmd, true);
    }

    public String exec(String cmd, boolean mountMaster) {
        if (cmd == null || cmd.trim().isEmpty()) {
            return "error: empty command";
        }
        File su = locator.suBinary();
        if (!su.exists()) {
            return "error: su binary not found";
        }

        ProcessBuilder pb;
        if (mountMaster) {
            // --mount-master ensures execution within global namespace
            pb = new ProcessBuilder(su.getAbsolutePath(), "--mount-master", "-c", cmd);
        } else {
            pb = new ProcessBuilder(su.getAbsolutePath(), "-c", cmd);
        }

        pb.redirectErrorStream(true);
        Map<String, String> env = pb.environment();
        env.remove("LD_LIBRARY_PATH");
        env.remove("LD_PRELOAD");
        pb.directory(appContext.getFilesDir());

        Process process = null;
        try {
            process = pb.start();
            StringBuilder out = new StringBuilder();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            String line;
            while ((line = reader.readLine()) != null) {
                out.append(line).append('\n');
            }
            int code = process.waitFor();
            String text = out.toString().trim();
            // If --mount-master is not supported by older su, retry without it
            if (mountMaster && code != 0 && (text.contains("invalid option") || text.contains("unrecognized option"))) {
                return exec(cmd, false);
            }
            if (code != 0 && text.isEmpty()) {
                return "error: su exited " + code;
            }
            return text;
        } catch (Exception e) {
            // Fallback retry without mount-master if process invocation failed
            if (mountMaster) {
                return exec(cmd, false);
            }
            return "error: " + e.getMessage();
        } finally {
            if (process != null) {
                process.destroy();
            }
        }
    }
}
