class BrewAutoupdate < Formula
  desc "Selectively auto-update Homebrew packages using fzf"
  homepage "https://github.com/victory-sokolov/brew-autoupdate"
  version "0.0.1"
  license "MIT"
  head "https://github.com/victory-sokolov/brew-autoupdate.git", branch: "main"

  depends_on "fzf"

  def install
    bin.install "bin/brew-autoupdate"
  end

  def caveats
    <<~EOS
      To get started, interactively select packages to auto-update:
        brew autoupdate select

      Then enable the background daemon (checks hourly by default):
        brew autoupdate start

      To check every 30 minutes instead:
        brew autoupdate start 1800

      View status and selected packages:
        brew autoupdate status
    EOS
  end

  test do
    assert_match "brew-autoupdate", shell_output("#{bin}/brew-autoupdate version")
  end
end
