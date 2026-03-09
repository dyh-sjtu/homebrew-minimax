cask "minimax" do
  arch arm: "-arm64", intel: ""

  version "3.0.12"

  on_arm do
    sha256 "c062feef97302f42c19c848aa0facd81dd24dd8cdaadc478921ada9872b4ba40"
  end
  on_intel do
    sha256 "afcfc091316885661eaa71a85f459060bb262e9db2e7a3b52dfc7b3a62e03108"
  end

  url "https://filecdn.minimax.chat/public/minimax-agent-prod/release/MiniMax-#{version}#{arch}.dmg"
  name "MiniMax"
  desc "MiniMax AI Agent desktop application (China)"
  homepage "https://www.minimaxi.com/"

  livecheck do
    url "https://filecdn.minimax.chat/public/minimax-agent-prod/release/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true
  depends_on macos: ">= :catalina"

  app "MiniMax.app"

  zap trash: [
    "~/Library/Application Support/MiniMax",
    "~/Library/Preferences/com.minimax.agent.cn.plist",
    "~/Library/Logs/MiniMax",
    "~/Library/Saved Application State/com.minimax.agent.cn.savedState",
  ]
end
