FancyCrash
==========

FancyCrash is designed to crash an iOS App with fancy visual effects.

Silent crash considers not user-friendly. Always give user a FANCY crash effect when possible.


Usage
-----

Copy `FancyCrash.h` & `.m` to your project. Call `[FancyCrash crash]` to get a random crash effect. Or use `[FancyCrash crashWithEffect:effectOptions:]` to customize the crash animation.


Customize Effects
-------

Options for `kFancyCrashEffectBreakGlass1`:

```
@{
    @"crackDuration"  : @0.5,     // crack animation duration
    @"fallDuration"   : @0.9,     // fall animation duration
    @"rows"           : @6,       // row count
    @"columns"        : @4,       // column count
}
```