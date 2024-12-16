# ![Taxi](taxi-logo-transparent.svg)
>The FTP Client that drives you anywhere

[![Build Status](https://travis-ci.org/Alecaddd/taxi.svg?branch=master)](https://travis-ci.org/Alecaddd/taxi)

Taxi is a native Linux FTP client built in Vala and Gtk originally created by Kiran John Hampal. It allows you to connect to a remote server with various Protocols (FTP, SFT, etc.), and offers an handy double paned interface to quickly transfer files and folders between your computer and the server.

![Taxi Screenshot](data/screenshot.png?raw=true)

<!-- ## Get it from the elementary OS AppCenter!
Taxi, is primarily available from the AppCenter of elementary OS. Download it from there!

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.alecaddd.taxi) -->

## Install it from source
You can install Taxi by compiling from source, here's the list of dependencies required:
 - `gtk+-3.0>=3.9.10`
 - `granite>=0.5.0`
 - `glib-2.0`
 - `gobject-2.0`
 - `libsoup-2.4`
 - `libsecret-1`
 - `meson`

## Building
```
meson build --prefix=/usr
cd build
ninja && sudo ninja install
```

## Installation

#### Arch Linux
Arch Linux users can find Taxi  under the name [taxi-git](https://aur.archlinux.org/packages/taxi-git/) in the **AUR**:

`$ aurman -S taxi-git`

#### Fedora
Fedora users can find Taxi  under the name [taxi](https://apps.fedoraproject.org/packages/taxi) in official repos:

`$ sudo dnf install taxi`

## Donations
If you like Taxi and you want to support its development, consider donating via [PayPal](https://www.paypal.me/alecaddd) or pledge on [Patreon](https://www.patreon.com/alecaddd).
