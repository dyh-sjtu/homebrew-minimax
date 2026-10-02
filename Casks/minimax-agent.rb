cask "minimax-agent" do
  arch arm: "-arm64", intel: ""

  version "3.1.0"
  sha256 arm:   "f367b9997e70bd304644b2d79b2c884c5aa92abd24be1dba9b1ba0ef06f73d1d",
         intel: "90d0354ef098da7a742d5fd549ea0ceb8da3947e132e4d6dc6c9f51216491b6d"

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

  auto_updates true
  conflicts_with cask: "minimax"
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
