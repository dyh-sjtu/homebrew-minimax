cask "minimax-code" do
  # 地区只由显式传入的 --language（或 HOMEBREW_CASK_OPTS="--language=..."）决定，不读系统语言：
  #   默认 / --language=zh -> 国内版；--language=en -> 海外版
  # 显式参数会写入 Caskroom/minimax-code/.metadata/config.json，brew upgrade 时沿用
  requested_language = [
    *cask.config.explicit.fetch(:languages, []),
    *cask.config.env.fetch(:languages, []),
  ].first.to_s
  overseas = requested_language.start_with?("en")

  release_base = if overseas
    "https://file.cdn.minimax.io/public/minimax-agent-prod/release"
  else
    "https://filecdn.minimax.chat/public/minimax-agent-prod/release"
  end

  old_macos_reason = if overseas
    "requires macOS 12 (Monterey) or later. " \
      "Please download a compatible build from the official website: https://agent.minimax.io/download"
  else
    "requires macOS 12 (Monterey) or later / 需要 macOS 12 (Monterey) 及以上版本，" \
      "当前系统请前往官网下载适配的安装包：https://agent.minimax.cn/download"
  end

  arch arm: "-arm64", intel: ""

  version "3.1.0"

  if overseas
    sha256 arm:   "c60099271e3eb2d76bee2c00a8095c38f4310ddeff76f3f91b53d2ec835d5514",
           intel: "47e642049d6bbba9037960de46506d108d3c417d3337f6514d9c532015b2c9b7"
  else
    sha256 arm:   "888725ec29348a50830aa14a5019d0867fad9e1b4f628f1c449aed551caadc27",
           intel: "d37533e456f5b911052a69a9f80f474d0539461f3755a016a049e3832d6c64d1"
  end

  on_big_sur :or_older do
    disable! date: "2026-09-29", because: old_macos_reason
  end

  language "zh", default: true do
    "zh"
  end
  language "en" do
    "en"
  end

  url "#{release_base}/MiniMax%20Code-#{version}#{arch}.dmg",
      verified: (release_base.delete_prefix("https://").delete_suffix("release") unless overseas)
  name "MiniMax Code"
  desc "AI agent desktop application"
  homepage overseas ? "https://agent.minimax.io/" : "https://agent.minimax.cn/"

  livecheck do
    url "#{release_base}/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true
  conflicts_with cask: "minimax-agent"
  depends_on macos: :monterey

  app "MiniMax Code.app"

  # userData 目录名与 bundle id 沿用旧值（国内 MiniMax / com.minimax.agent.cn，海外 MiniMax Agent / com.minimax.agent）
  zap trash: [
    "~/.minimax",
    "~/Library/Application Support/MiniMax Agent",
    "~/Library/Application Support/MiniMax",
    "~/Library/Caches/com.minimax.agent",
    "~/Library/Caches/com.minimax.agent.cn",
    "~/Library/Caches/com.minimax.agent.cn.ShipIt",
    "~/Library/Caches/com.minimax.agent.ShipIt",
    "~/Library/HTTPStorages/com.minimax.agent",
    "~/Library/HTTPStorages/com.minimax.agent.cn",
    "~/Library/Logs/MiniMax Agent",
    "~/Library/Logs/MiniMax",
    "~/Library/Preferences/com.minimax.agent.cn.plist",
    "~/Library/Preferences/com.minimax.agent.plist",
    "~/Library/Saved Application State/com.minimax.agent.cn.savedState",
    "~/Library/Saved Application State/com.minimax.agent.savedState",
  ]
end
