cask "minimax-agent" do
  arch arm: "-arm64", intel: ""

  version "3.1.0"
  sha256 arm:   "c60099271e3eb2d76bee2c00a8095c38f4310ddeff76f3f91b53d2ec835d5514",
         intel: "47e642049d6bbba9037960de46506d108d3c417d3337f6514d9c532015b2c9b7"

  on_big_sur :or_older do
    disable! date:    "2026-09-29",
             because: "requires macOS 12 (Monterey) or later. " \
                      "Please download a compatible build from the official website: https://agent.minimax.io/download"
  end

  url "https://file.cdn.minimax.io/public/minimax-agent-prod/release/MiniMax%20Code-#{version}#{arch}.dmg"
  name "MiniMax Code"
  desc "MiniMax AI agent desktop application"
  homepage "https://www.minimax.io/"

  livecheck do
    url "https://file.cdn.minimax.io/public/minimax-agent-prod/release/latest-mac.yml"
    strategy :electron_builder
  end

  deprecate! date:    "2026-10-02",
             because: "has been replaced by minimax-code. Migrate with: " \
                      "brew uninstall --cask minimax-agent && brew install --cask minimax-code --language=en"

  auto_updates true
  conflicts_with cask: "minimax-code"
  depends_on macos: :monterey

  app "MiniMax Code.app"

  # userData 目录名与 bundle id 沿用旧值（见 apps/electron/main/config/app-identity.ts），保证升级后数据连续
  zap trash: [
    "~/.minimax",
    "~/Library/Application Support/MiniMax Agent",
    "~/Library/Caches/com.minimax.agent",
    "~/Library/Caches/com.minimax.agent.ShipIt",
    "~/Library/HTTPStorages/com.minimax.agent",
    "~/Library/Logs/MiniMax Agent",
    "~/Library/Preferences/com.minimax.agent.plist",
    "~/Library/Saved Application State/com.minimax.agent.savedState",
  ]
end
