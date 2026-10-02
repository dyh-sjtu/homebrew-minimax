cask "minimax" do
  arch arm: "-arm64", intel: ""

  version "3.1.0"
  sha256 arm:   "062cfe53fe801dba5b8058c1f752f27397565e84af43e8feba30e9cf0ec53df0",
         intel: "b931fc9a5b8494b8efb4d35e6fa3a7bc63c214250faa42ca9e0e9a65dbe254a4"

  on_big_sur :or_older do
    disable! date:    "2026-09-29",
             because: "requires macOS 12 (Monterey) or later / " \
                      "需要 macOS 12 (Monterey) 及以上版本，" \
                      "当前系统请前往官网下载适配的安装包：https://agent.minimax.cn/download"
  end

  url "https://filecdn.minimax.chat/public/minimax-agent-prod/release/MiniMax%20Code-#{version}#{arch}.dmg"
  name "MiniMax Code"
  desc "AI agent desktop application (China)"
  homepage "https://www.minimaxi.com/"

  livecheck do
    url "https://filecdn.minimax.chat/public/minimax-agent-prod/release/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true
  conflicts_with cask: "minimax-agent"
  depends_on macos: :monterey

  app "MiniMax Code.app"

  # userData 目录名与 bundle id 沿用旧值（见 apps/electron/main/config/app-identity.ts），保证升级后数据连续
  zap trash: [
    "~/.minimax",
    "~/Library/Application Support/MiniMax",
    "~/Library/Caches/com.minimax.agent.cn",
    "~/Library/Caches/com.minimax.agent.cn.ShipIt",
    "~/Library/HTTPStorages/com.minimax.agent.cn",
    "~/Library/Logs/MiniMax",
    "~/Library/Preferences/com.minimax.agent.cn.plist",
    "~/Library/Saved Application State/com.minimax.agent.cn.savedState",
  ]
end
