# Homebrew Distribution (Prebuilt Binary)

This document explains how to distribute `swiftnumbers` as a prebuilt executable so users do not compile from source at install time.

## Goal

- Publish GitHub Releases with prebuilt `swiftnumbers` binaries for macOS:
  - Apple Silicon (`arm64`)
  - Intel (`x86_64`)
- Install via Homebrew tap using a binary formula.

## Release Assets Produced by CI

Workflow: `.github/workflows/release-binaries.yml`

When a GitHub Release is published, CI uploads:

- `swiftnumbers_<version>_darwin_arm64.tar.gz`
- `swiftnumbers_<version>_darwin_arm64.tar.gz.sha256`
- `swiftnumbers_<version>_darwin_x86_64.tar.gz`
- `swiftnumbers_<version>_darwin_x86_64.tar.gz.sha256`

Each archive contains a single executable file: `swiftnumbers`.

## Homebrew Tap Setup (one-time)

1. Create a tap repository:

```bash
brew tap-new <github-user>/tap
```

2. Push it to GitHub (recommended repository name: `homebrew-tap`).
3. Add formula file to `Formula/swiftnumbers.rb` in that tap repository.

Reference: [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)

## Formula Template

Use this as a starting point inside your tap repository (`Formula/swiftnumbers.rb`):

```ruby
class Swiftnumbers < Formula
  desc "Native Swift library and CLI for reading and editing Apple .numbers documents"
  homepage "https://github.com/pizzamoltobene/swift-numbers"
  version "0.4.0"
  license "AGPL-3.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/pizzamoltobene/swift-numbers/releases/download/v#{version}/swiftnumbers_#{version}_darwin_arm64.tar.gz"
      sha256 "<ARM64_SHA256>"
    else
      url "https://github.com/pizzamoltobene/swift-numbers/releases/download/v#{version}/swiftnumbers_#{version}_darwin_x86_64.tar.gz"
      sha256 "<X86_64_SHA256>"
    end
  end

  def install
    bin.install "swiftnumbers"
  end

  test do
    assert_match "USAGE:", shell_output("#{bin}/swiftnumbers --help")
  end
end
```

Notes:
- Replace `version` and SHA256 values for every release.
- Homebrew verifies SHA256 during install.

References:
- [Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- Example formula style with arch-specific URLs: [anomalyco/homebrew-tap `opencode.rb`](https://github.com/anomalyco/homebrew-tap/blob/master/opencode.rb)

## Release-to-Tap Update Flow

1. Publish release tag in this repo (`vX.Y.Z`).
2. Wait for `Release Binaries` workflow to complete.
3. Copy the generated asset URLs and SHA256 values into tap formula.
4. Commit and push tap formula update.
5. Verify install from a clean machine:

```bash
brew install <github-user>/tap/swiftnumbers
swiftnumbers --help
```

## End-User Install

```bash
brew install <github-user>/tap/swiftnumbers
```

Homebrew will fetch the prebuilt binary archive for the user architecture; no local Swift compile is required.
