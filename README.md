# skvim - Secure Vim with Application Allowlisting

**skvim** is a security-focused vim editor that provides application allowlisting functionality to control which applications can execute vim commands. It addresses the bundle ID inheritance vulnerability in macOS applications that could potentially allow unauthorized vim execution.

This small project turns accessible(!) input fields on macOS into full vim buffers. It should behave and feel like native vim, because, under the hood I synchronize the text field with a real vim buffer.

![demo](https://user-images.githubusercontent.com/22680421/153753171-e818d40b-4d72-4b88-9719-d1e36d16dec0.gif)

You can use all modes (even commandline etc.) and all commands included in vim.

## Features

- **Application Allowlisting**: Configure which applications are allowed to execute vim functionality
- **Bundle ID Security**: Prevents unauthorized applications from inheriting vim capabilities through bundle ID manipulation
- **Accessibility Integration**: Secure integration with macOS accessibility APIs
- **Configuration Management**: Flexible configuration through allowlist files
- **Custom Configuration**: Load custom `skvimrc` files with vim configurations and remappings

## Security Improvements

This version has been professionally audited and improved for security:

- Stack protection and buffer overflow prevention
- Secure memory management with proper error handling
- Input validation and sanitization
- Replaced dangerous `vfork()` with secure `posix_spawn()`
- Secure lockfile creation to prevent race conditions
- Compiler hardening flags enabled

## Configuration

It is possible to load a custom `skvimrc` file, which can contain custom vim configurations, e.g. remappings (see the examples folder).

Additionally, you can edit the `allowlist` file in the `~/.config/skvim/` folder to manually specify which applications should be handled by skvim. You will only want to include applications where you want vim functionality, such as text editors, IDEs, and browsers.

Every time the vim mode changes, or a commandline update is issued, the script `skvim.sh` in the folder `~/.config/skvim/` is executed where you can handle how you want to process this information.

(!): Accessible means, that the input field needs to conform to the accessibility standards for text input fields, else there is nothing we can do.

## Installation

### Via Homebrew

```bash
brew tap tadeucbm/skvim
brew install skvim
```

### Building from Source

```bash
git clone https://github.com/tadeucbm/SketchyVim-Allowlist.git
cd SketchyVim-Allowlist
make
```

You will be asked to grant accessibility permissions when first running skvim.

You can change the macOS selection color to anything you like with this command (which is my green):
```bash
defaults write NSGlobalDomain AppleHighlightColor -string "0.615686 0.823529 0.454902"
```

## Requirements

- macOS 12.0 or later
- Accessibility permissions

## Known Issues

* Multikey remappings are not recognized (e.g. jk for esc)
* Some text fields break the accessibility api and this leads to bugs, be sure to add only the apps you want to the allowlist. Sometimes it helps to switch to a "raw" or "markdown" editing mode on websites, such that there is no interference. Generally, Safari seems to make most text fields available, while Firefox does not.

## Contributions

Pull requests are welcome. If you improve the code for your own use, consider creating a pull request, such that all people (including me) can enjoy those improvements.

## Credits

* I use the libvim library which is a compact and minimal c library for the vim core.
* Many prior projects tried to accomplish a similar vision by rebuilding the vim movements by hand, those have inspired me to create this project.

## Security Disclosure

If you discover security vulnerabilities, please report them responsibly to the project maintainer.

## License

MIT License - see LICENSE file for details.
