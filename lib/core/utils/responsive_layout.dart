/// Narrow phones vs taller phablets — keeps tap targets and typography sane.
enum AppBreakpoint { compact, comfortable }

AppBreakpoint breakpointForWidth(double width) =>
    width < 400 ? AppBreakpoint.compact : AppBreakpoint.comfortable;

double horizontalPaddingForWidth(double width) =>
    breakpointForWidth(width) == AppBreakpoint.compact ? 16.0 : 20.0;

double homeGreetingSizeForWidth(double width) =>
    breakpointForWidth(width) == AppBreakpoint.compact ? 26.0 : 30.0;
