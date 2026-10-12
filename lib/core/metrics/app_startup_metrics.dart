/// Global startup timing metrics tracker
class AppStartupMetrics {
  static final Stopwatch startupStopwatch = Stopwatch();
  static bool hasRenderedFirstFrame = false;
  static bool hasNavigatedSplash = false;

  static void start() {
    if (!startupStopwatch.isRunning) {
      startupStopwatch.start();
    }
  }

  static int get elapsedMs => startupStopwatch.elapsedMilliseconds;
}
