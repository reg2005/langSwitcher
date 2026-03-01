---
title: 'LangSwitcher'
description: 'Free, open-source keyboard layout converter for macOS. Press a hotkey — get mistyped text fixed instantly.'
navigation: false
---

::u-page-hero
---
orientation: horizontal
---

#title
Fix mistyped text in one keystroke on macOS

#description
Typed in the wrong keyboard layout? Press **Shift** twice and LangSwitcher converts it instantly. A free, open-source macOS menu bar app — no selection needed, Smart Conversion handles it.

#links
  :::u-button
  ---
  to: /en/getting-started/installation
  icon: i-lucide-rocket
  size: xl
  ---
  Getting Started
  :::

  :::u-button
  ---
  to: https://github.com/reg2005/langSwitcher
  icon: i-simple-icons-github
  size: xl
  variant: subtle
  ---
  View on GitHub
  :::

  :::u-button
  ---
  to: /en/guide/donate
  icon: i-lucide-hand-heart
  size: xl
  variant: subtle
  ---
  Donate
  :::

::

::u-page-section
#title
See it in action

#default
  :::demo-video
  ---
  src: /langSwitcher/langSwitch.mp4
  maxWidth: 640px
  ---
  :::
::

::u-page-section
#title
How it works

#default
  :::u-page-columns
    ::::u-page-card
    ---
    icon: i-lucide-keyboard
    ---
    #title
    1. You type in the wrong layout

    #description
    `ghbdtn rfr ltkf` — happens to every bilingual user.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-zap
    ---
    #title
    2. Press ⇧⇧ (Double Shift)

    #description
    No need to select text — Smart Conversion detects the boundary automatically.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-check-circle
    ---
    #title
    3. Text is fixed

    #description
    `привет как дела` — converted in milliseconds, pasted back in place.
    ::::
  :::
::

::u-page-section
#title
Features

#default
  :::u-page-grid
    ::::u-page-card
    ---
    icon: i-lucide-zap
    ---
    #title
    Instant Conversion

    #description
    Press a hotkey and text is converted in milliseconds through clipboard-based replacement. Works in any app.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-brain
    ---
    #title
    Smart Conversion

    #description
    No need to select text. Greedy Line mode auto-detects where the wrong layout begins and converts only what's needed.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-keyboard
    ---
    #title
    Double Shift Hotkey

    #description
    Default hotkey: press Shift twice quickly. Or record any custom shortcut in Settings.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-scroll-text
    ---
    #title
    Conversion Log

    #description
    Every conversion is logged to a local SQLite database. Rate results, export as JSON for ML training.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-globe
    ---
    #title
    5 Layouts

    #description
    English, Russian, German, French, Spanish. Auto-detected from system keyboard settings.
    ::::

    ::::u-page-card
    ---
    icon: i-lucide-shield-check
    ---
    #title
    Privacy First

    #description
    No data leaves your Mac. No analytics, no telemetry, no network access. Fully offline. Open source under MIT.
    ::::
  :::
::

::u-page-section
#title
Open Source & Community

#description
LangSwitcher is free, open-source software under the MIT license. Contributions are welcome!

#links
  :::u-button
  ---
  to: https://github.com/reg2005/langSwitcher/issues
  icon: i-lucide-bug
  variant: subtle
  ---
  Report a Bug
  :::

  :::u-button
  ---
  to: https://github.com/reg2005/langSwitcher
  icon: i-lucide-git-pull-request
  variant: subtle
  ---
  Contribute
  :::

  :::u-button
  ---
  to: /en/guide/donate
  icon: i-lucide-hand-heart
  variant: subtle
  ---
  Donate
  :::
::
