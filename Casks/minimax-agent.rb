cask "minimax-agent" do
  arch arm: "-arm64", intel: ""

  version "3.0.12"

  on_arm do
    sha256 "f30a359e3dea51a96b0371d84775363b93ee0de893a4ff2ec0497794c1c33bc0"
  end
  on_intel do
    sha256 "1c9358e1cb1d2617a8eebb741cfe823b1b804c5ca658167b1ebf679af2835ebe"
  end

  url "https://file.cdn.minimax.io/public/minimax-agent-prod/release/MiniMax%20Agent-#{version}#{arch}.dmg"
  name "MiniMax Agent"
  desc "MiniMax AI Agent desktop application"
  homepage "https://www.minimax.io/"

  livecheck do
    url "https://file.cdn.minimax.io/public/minimax-agent-prod/release/latest-mac.yml"
    strategy :electron_builder
  end

  auto_updates true
  depends_on macos: ">= :catalina"

  app "MiniMax Agent.app"

  zap trash: [
    "~/Library/Application Support/MiniMax Agent",
    "~/Library/Preferences/com.minimax.agent.plist",
    "~/Library/Logs/MiniMax Agent",
    "~/Library/Saved Application State/com.minimax.agent.savedState",
  ]
end
